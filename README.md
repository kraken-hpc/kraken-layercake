# Kraken/Layercake

Kraken "Layercake" is a [kraken](https://github.com/kraken-hpc/kraken)-based tool for provisioning and managing clusters of physical (or virtual) computer 
systems, such as those used in high-performance compute clusters.

## The layer design
"Layercake" refers to the model used to manage systemm images.  As opposed to traditional HPC management systems, Layercake provisions nodes in layers:

1) **Layer0**: aka the MinimalOS or MinOS - A light-weight, persistent OS image that runs services needed to automate and orchestrate loading higher layers.  This layer runs a kraken-based layercake agent and the [imageapi](https://github.com/kraken-hpc/imageapi) service that loads higher-level functionality (Layer1), called "ImageSets" on top of the Layer0 as Linux namespaced containers.
2) **Layer1**: aka ImageSets are sets of container images (potentially full, systemd-based system images) that are loaded on top of Layer0.  They represent higher-level functions of the node in the system, such as the ability to run job schedulers and traditional system management tools.
3) **Layer2**: the intended layer for jobs to run.  Layer2 is an additional layer typically containing user-provided software, e.g. scientific software.  

This layered model provides many advantages, including the ability to dynamic "roll" system images extremely rapidly and even transparently to the end-user.

## Automation

Because Layercake is kraken-based, it inherits all of the distributed automation features of the kraken framework.  For instance, all of the orchestration of the Layercake layers is automated and self-healing.

## Examples

To try out the Layercake system, take a look at the Examples (see their README files for more details) contained in [/examples](/examples).

## Status

The Layercake stack is functional.  Owing to the recent split of this project from the kraken framework, documentation and examples are in active development.  Check back soon.

## Contact us

There are two primary ways to get in contact with us:
1. Submit an Issue or Pull Request
2. Come talk to us on Slack. To join, see [kraken-hpc.io](http://kraken-hpc.io).
