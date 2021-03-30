/* includes.go.tpl: used to include modules & extensions specified in build config
 *
 * Author: J. Lowell Wofford <lowell@lanl.gov>
 *
 * This software is open source software available under the BSD-3 license.
 * Copyright (c) 2018, Triad National Security, LLC
 * See LICENSE file for details.
 */

package main

// Extensions

import (
	_ "github.com/kraken-hpc/kraken-layercake/extensions/hypervisor"

	_ "github.com/kraken-hpc/kraken-layercake/extensions/imageapi"

	_ "github.com/kraken-hpc/kraken/extensions/ipv4"

	_ "github.com/kraken-hpc/kraken-layercake/extensions/pxe"

	// Modules

	_ "github.com/kraken-hpc/kraken-layercake/modules/libvirt"

	_ "github.com/kraken-hpc/kraken-layercake/modules/imageapi"

	_ "github.com/kraken-hpc/kraken-layercake/modules/pxe"

	_ "github.com/kraken-hpc/kraken/modules/restapi"

	_ "github.com/kraken-hpc/kraken-layercake/modules/vboxmanage"

	_ "github.com/kraken-hpc/kraken/modules/websocket"
)
