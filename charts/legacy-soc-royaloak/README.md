# legacy-soc-royaloak

![Version: 1.0.0](https://img.shields.io/badge/Version-0.0.0--rc.01a9cdd.20250902234251-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-0.0.0--rc.01a9cdd.20250902234251-informational?style=flat-square)

legacy-soc-royaloak is a legacy multimedia application.

**Homepage:** <https://legacy-soc-royaloak.ltc.bcit.ca>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| BCIT LTC | <ltc_techops@bcit.ca> | <https://www.bcit.ca/learning-teaching-centre/> |

## Installing the Chart

Our registry images are public, but in ["Working with Container Registries"](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) GitHub says:
> "You need an access token to publish, install, and delete private, internal, and public packages."

1. Create a [GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) and set it in your terminal shell:

        rexport CR_PAT=YOUR_TOKEN

2. Install [Helm](https://helm.sh/docs/intro/install) and [jq](https://jqlang.org/download/).

3. Login to the global GitHub registry service:

        echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin

4. List the available registry tags

        curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $CR_PAT" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/orgs/bcit-ltc/packages/container/legacy-soc-royaloak/versions \
        | jq '.[].metadata.container.tags.[]'

5. Pull and inspect the helm chart:

        helm pull --untar oci://ghcr.io/bcit-ltc/legacy-soc-royaloak --version {VERSION}

6. Install the chart:

        helm install legacy-soc-royaloak .

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `5` |  |
| autoscaling.minReplicas | int | `2` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| container.port | int | `8080` |  |
| defaultDomain | string | `"ltc.bcit.ca"` |  |
| extraEnv | list | `[]` |  |
| extraEnvFrom | list | `[]` |  |
| extraVolumeMounts[0].mountPath | string | `"/tmp"` |  |
| extraVolumeMounts[0].name | string | `"tmp"` |  |
| extraVolumes[0].emptyDir | object | `{}` |  |
| extraVolumes[0].name | string | `"tmp"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.registry | string | `"ghcr.io"` |  |
| image.repository | string | `"bcit-ltc/legacy-soc-royaloak"` |  |
| image.tag | string | `"1.0.0"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `true` |  |
| ingress.extraPaths | list | `[]` |  |
| ingress.host | string | `""` |  |
| ingress.ingressClassName | string | `""` |  |
| ingress.tlsSecret | string | `"star-ltc-bcit-ca"` |  |
| livenessProbe.httpGet.path | string | `"/"` |  |
| livenessProbe.httpGet.port | int | `8080` |  |
| livenessProbe.initialDelaySeconds | int | `10` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| name | string | `"legacy-soc-royaloak"` |  |
| networkPolicy.enabled | bool | `false` |  |
| nodeSelector | object | `{}` |  |
| pdb.enabled | bool | `false` |  |
| pdb.minAvailable | int | `1` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| progressDeadlineSeconds | int | `600` |  |
| readinessProbe.httpGet.path | string | `"/"` |  |
| readinessProbe.httpGet.port | int | `8080` |  |
| readinessProbe.initialDelaySeconds | int | `3` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| revisionHistoryLimit | int | `3` |  |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| securityContext.runAsGroup | int | `101` |  |
| securityContext.runAsUser | int | `101` |  |
| service.annotations | object | `{}` |  |
| service.port | int | `8080` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.automount | bool | `true` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| startupProbe.failureThreshold | int | `30` |  |
| startupProbe.httpGet.path | string | `"/"` |  |
| startupProbe.httpGet.port | int | `8080` |  |
| startupProbe.periodSeconds | int | `2` |  |
| tolerations | list | `[]` |  |
| useDefaultNginxConfig | bool | `true` |  |

## Building this README.md

        docker run -it --volume "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:latest helm-docs --template-files=./files/_README.md.gotmpl

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
