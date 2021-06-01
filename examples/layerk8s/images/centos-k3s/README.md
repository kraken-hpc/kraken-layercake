# centos-k3s image

This image will join nodes as agents to a k3s cluster.

This image is based on `centos-base`, and you should build that image first.

## Usage

You'll want to customize a few things in this directory:

1. Set the TOKEN variable in `Dockerfile` to your k3s node token.  You can find this value at `/var/lib/rancher/k3s/server/node-token`.

2. Then you can build your image with `build-layer1 centos-base`.

You should be able to boot nodes with this image and see that they join k3s as nodes with `kubectl get nodes`.
