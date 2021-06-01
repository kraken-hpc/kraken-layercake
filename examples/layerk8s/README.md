# layerk8s

This example provides scripts, definitions, and tools to deploy a full-featured Layercake cluster using k3s for service management.

***This guide is under construction.  Check back soon for a step-by-step guide and runnable example.***

Meanwhile, you can find much of what you need to get started in the following directories:

- `ansible` - contains the ansible definitions need to generate Layercake state definitions.
- `docker` - contains definitions for some custom docker images you'll need if you want to run a Slurm cluster` .
- `images` - contains image building tools and some example image definitions.
- `k8s` - contains all of the kubernetes definitions (including configmap files) needed to deploy the k3s services.
- `scripts` - contains some helper scripts.

Each directory has a more specific `README.md`.

The high-level setup procedure:

1. Install `podman` and `buildah` (we use those under the hood quite a bit)
2. Install k3s (see `scripts/k3s.sh` and `scripts/rancher/*`)
3. Deploy the private registry with `k8s/docker-registry`
4. Build the docker images in `docker/*` and push them to the private registry.
5. Make sure all of the configs in `k8s/*/configmaps` match your site config, deploy them.
6. Deploy all of `k8s/*/*.yaml` .
7. Build some images using the tools/definitions in `images/*`
8. Edit your `ansible/group_vars` as necessary for site config.
9. (in `ansible`) Run `ansible-playbook -i hosts site.yaml -e 'kraken_api_method=POST'` to deploy your nodes.
   Note: `-e 'kraken_api_method=POST'` is only needed the first time you run ansible against a freshly running layercake.  Leave that off to update a running system.
