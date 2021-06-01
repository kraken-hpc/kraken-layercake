# k8s

This directory contains all of the definitions needed to deploy the kubernetes portion of layerk8s.

You probably want to update the files that used to generate config maps prior to launching deployments.

To illustrate structure, you could launch everything with:

```bash
for d in *; do
    [ -d $d ] || continue
    (
        cd $d
        # create configmaps
        for cm in configmaps/*; do
            (
                cd $cm
                if [ $( ls | wc -l ) -gt 1 ]; then
                    # configmap is a directory of files
                    kubectl create configmap $(basename $PWD) --from-file . --dry-run=client -o yaml | kubectl apply -f -
                else
                    # configmap is a single file
                    kubectl create configmap $(basename $PWD) --from-file $(ls) --dry-run=client -o yaml | kubectl apply -f -
                fi
            )
        done
        # Apply svcs/deployments
        for f in *.yaml; do
            kubectl apply -f $f
        done
    )
done
```
