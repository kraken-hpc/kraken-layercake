package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"regexp"
	"strings"
	"text/template"

	"github.com/davecgh/go-spew/spew"
	"github.com/kraken-hpc/kraken/core"
	"github.com/kraken-hpc/kraken/lib/types"
	"github.com/sirupsen/logrus"
)

var socketFile = "unix:/tmp/kraken.sock"
var cmdline = "/proc/cmdline"

var cmdRE = regexp.MustCompile(`kraken.id=([0-9a-zA-Z\-]+)`)

func getUID(cmdline string) (string, error) {
	d, e := ioutil.ReadFile(cmdline)
	if e != nil {
		return "", fmt.Errorf("failed to extract node ID; could not read kernel commandline: %v", e)
	}
	m := cmdRE.FindAllStringSubmatch(string(d), 1)
	if len(m) == 0 {
		return "", fmt.Errorf("failed to extract node ID: no match foudn in kernel commandline")
	}
	return m[0][1], nil
}

type OptionsType struct {
	cmdLine string
	dsc     bool
	id      string
	inFile  string
	outFile string
	target  string
}

var Options = &OptionsType{}

func main() {
	Log := logrus.New().WithField("applciation", "kraken-template")
	flag.StringVar(&Options.id, "id", "", "provide the node ID to template on. If unspecified, read from kernel commandline.")
	flag.StringVar(&Options.inFile, "in", "", "input template file. If unspecified, read from stdin.")
	flag.StringVar(&Options.outFile, "out", "", "output file. If unspecified, write to stdout.")
	flag.StringVar(&Options.target, "target", socketFile, "connection string for kraken instance.")
	flag.StringVar(&Options.cmdLine, "cmdline", cmdline, "kernel commandline file to read from.")
	flag.BoolVar(&Options.dsc, "dsc", false, "query discoverable state instead of configuration state")
	flag.Parse()

	var e error
	if Options.id == "" {
		if Options.id, e = getUID(Options.cmdLine); e != nil {
			Log.WithError(e).Fatal("failed to get ID")
		}
	}

	// get node data
	api := core.NewModuleAPIClient(Options.target)
	var n types.Node
	if Options.dsc {
		n, e = api.QueryRead(Options.id)
	} else {
		n, e = api.QueryRead(Options.id)
	}
	if e != nil {
		Log.WithError(e).Fatal("failed to get node state data")
	}
	var node map[string]interface{}
	fmt.Printf("%s\n", n.JSON())
	json.Unmarshal(n.JSON(), &node)

	var in []byte
	if Options.inFile != "" {
		if in, e = ioutil.ReadFile(Options.inFile); e != nil {
			Log.WithError(e).Fatal("failed to open template input file")
		}
	} else {
		if in, e = ioutil.ReadAll(os.Stdin); e != nil {
			Log.WithError(e).Fatal("error reading stdin")
		}
	}

	var t *template.Template
	if t, e = template.New("node").Funcs(template.FuncMap{}).Parse((string)(in)); e != nil {
		Log.WithError(e).Fatal("failed to parse template")
	}
	// rewrite extensions to be a map
	extMap := map[string]interface{}{}
	// we want extensions and services to be more easily accessed by name
	if exts, ok := node["extensions"]; ok {
		for _, e := range exts.([]interface{}) {
			if em, ok := e.(map[string]interface{}); ok {
				if v, ok := em["@type"]; ok {
					ts := strings.Split(v.(string), "/")
					extMap[ts[len(ts)-1]] = e
				}
			}
		}
	}
	node["extensionsByName"] = extMap
	// rewrite services to be a map
	srvMap := map[string]interface{}{}
	if srvs, ok := node["services"]; ok {
		for _, s := range srvs.([]interface{}) {
			if sm, ok := s.(map[string]interface{}); ok {
				if v, ok := sm["id"]; ok {
					srvMap[v.(string)] = s
				}
			}
		}
	}
	node["servicesByName"] = srvMap
	spew.Dump(node)

	var out *os.File
	if Options.outFile != "" {
		if out, e = os.Create(Options.outFile); e != nil {
			Log.WithError(e).Fatal("failed to create output file")
		}
	} else {
		out = os.Stdout
	}
	if e = t.Execute(out, node); e != nil {
		Log.WithError(e).Fatal("failed to execute template")
	}
}
