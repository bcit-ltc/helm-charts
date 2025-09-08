# Helm Charts

Helm charts for apps and services built and maintained by BCIT's Learning and Teaching Centre.

## Usage

[Helm](https://helm.sh/) must be installed to use the charts. Please refer to Helm’s documentation to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add bcit-ltc https://bcit-ltc.github.io/helm-charts

If you have already added this repo, run `helm repo update` to retrieve the latest versions of the packages.

Run `helm search repo bcit-ltc` to see the charts.

Chart OCI images are also available at [https://ghcr.io/bcit-ltc/oci/{appName}](https://ghcr.io/bcit-ltc/oci/{appName}).

## License

This Source Code Form is subject to the terms of the Mozilla Public License, v2.0. If a copy of the MPL was not distributed with this file, You can obtain one at <https://mozilla.org/MPL/2.0/>.

## About

Developed in 🇨🇦 Canada by the [Learning and Teaching Centre](https://www.bcit.ca/learning-teaching-centre/) at [BCIT](https://www.bcit.ca/).
