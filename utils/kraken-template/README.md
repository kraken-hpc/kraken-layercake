# kraken-template

`kraken-template` is a utility to template simple text files using variables from a running kraken application's state.

## Building

```bash
cd $KARKEN_SRC/util/kraken-template
CGO_ENABLED=0 go build .
```

Alternatively, `freebusy` can be built into the `u-root` busybox.

## Usage

```bash
$ kraken-template -h
Usage of kraken-template:
  -cmdline string
        kernel commandline file to read from. (default "/proc/cmdline")
  -dsc
        query discoverable state instead of configuration state
  -id string
        provide the node ID to template on. If unspecified, read from kernel commandline.
  -in string
        input template file. If unspecified, read from stdin.
  -out string
        output file. If unspecified, write to stdout.
  -target string
        connection string for kraken instance. (default "unix:/tmp/kraken.sock")
```

## Templating

`kraken-templte` uses the Go [text/template](https://pkg.go.dev/text/template) engine to fill templates.  It pulls the node state information for one node specified by `-id` (or the kernel commandline).  By default it will pull the configuration node state, though it can pull the discoverable node state if `-dsc` is specified.  The full node state an be referenced within the template, e.g. `{{ .nodename }}` would fill out the node's name.  All string objects are printed as they would be in JSON, e.g. `{{ .id }}` will print a human-readable UUID.

In addition to the node state object, two structures are added to make looking up extensions and services easier.  `exptensionsByName` and `servicesByName` are maps from extension/service name to their content.  Because proto objects contain a period in their name, e.g. `IPv4.IPv4OverEthernet`, you will want to use the `index` function with these maps, e.g. `{{ ( index extensionsByName "IPv4.IPv4OverEthernet ).ifaces.hsn.ip.subnet }}` would provide the appropriate path to the subnet address of an interface named "hsn."

## Example Usage

Suppose you would like to configure a secondary Infiniband interface for each node using Kraken states.  You could set up a `ib` object for each node under the `IPv4` extension.  This might look like:

```json
{
    "@type": "type.googleapis.com/IPv4.IPv4OverEthernet",
    "ifaces": {
        "kraken": {
            // ...
        },
        "ib0": {
            "ip": {
                "ip": "10.11.12.87",
                "subnet": "255.255.254.0"
            }
        }
    }
}
```

We can now create a template to fill out an ifcfg file for this interface:

File: `/etc/sysconfig/network-scripts/ifcfg-ib0`

```jinja2
TYPE=Infiniband
DEVICE=ib0
BOOTPROTO=none
ONBOOT=yes
NETMASK={{ ( index extensionByName "IPv4.IPv4OverEthernet" ).ifaces.ib0.ip.subnet }}
IPADDR={{ ( index extensionByName "IPv4.IPv4OverEthernet" ).ifaces.ib0.ip.ip }}
```

Now, instruct the imageapi to build this template on image start.
