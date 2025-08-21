# Helm Charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add bcit-ltc https://bcit-ltc.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
bcit-ltc` to see the charts.

To install the `course-workload-estimator` chart:

    helm install course-workload-estimator bcit-ltc/course-workload-estimator

To uninstall the chart:

    helm uninstall course-workload-estimator

Chart OCI images are also available at [https://ghcr.io/bcit-ltc/oci/{appName}](https://ghcr.io/bcit-ltc/oci/{appName}).
