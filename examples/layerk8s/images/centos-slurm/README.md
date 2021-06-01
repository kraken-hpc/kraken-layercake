# centos-k3s image

This image will join nodes as compute nodes in a Slurm cluster.

This image is based on `centos-base`, and you should build that image first.

## Usage

You'll want to customize a few things in this directory:

1. Populate `munge.key` with your real `munge.key`.  If you don't have one, create one with the `create-munge-key` command.

2. Copy-in your `slurm.conf`.  This should be the same `slurm.conf` you use to deploy the `slurmctld` service.

3. Then you can build your image with `build-layer1 centos-slurm`.

You should be able to boot nodes with this image and see them join Slurm.
