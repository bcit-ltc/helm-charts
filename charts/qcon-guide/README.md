# qcon-guide

![Version: 1.0.2](https://img.shields.io/badge/Version-1.0.2-informational?style=flat-square) ![AppVersion: 1.0.2](https://img.shields.io/badge/AppVersion-1.0.2-informational?style=flat-square)

Information about how to use [Qcon](https://qcon.ltc.bcit.ca).

**Homepage:** <https://qcon-guide.ltc.bcit.ca>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| BCIT LTC | <ltc_techops@bcit.ca> | <https://www.bcit.ca/learning-teaching-centre/> |

## Installing the Chart

Our registry images are public, but in ["Working with Container Registries"](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) GitHub says:
> "You need an access token to publish, install, and delete private, internal, and public packages."

1. Create a [GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) and set it in your terminal shell:

    ```console
    export CR_PAT=YOUR_TOKEN
    ```

1. Install [Helm](https://helm.sh/docs/intro/install) and [jq](https://jqlang.org/download/).

1. Login to the global GitHub registry service:

    ```console
    echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
    ```

1. List the available registry tags

    ```console
    curl -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $CR_PAT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/orgs/bcit-ltc/packages/container/qcon-guide/versions \
    | jq '.[].metadata.container.tags.[]'
    ```

1. Pull and inspect the helm chart:

    ```console
    helm pull --untar oci://ghcr.io/bcit-ltc/qcon-guide --version {VERSION}
    ```

1. Install the chart:

    ```console
    helm install qcon-guide .
    ```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backend | object | `{}` | Configuration for the backend |
| backend.auth | object | `{}` | Configures backend endpoint authentication |
| backend.auth.existingSecret | string | `""` | `Secret` (preferred) Must have keys<br>   &nbsp;&nbsp;POSTGRES_DB<br>   &nbsp;&nbsp;POSTGRES_USER<br>   &nbsp;&nbsp;POSTGRES_PASSWORD<br> If an existing secret name is not provided, the chart will create one. |
| backend.enabled | bool | `false` | Enable or disable backend components. |
| backend.image | string | `"postgres:16"` | Specifies the backend container image |
| backend.service | object | `{"name":"backend","port":5432}` | Configures a service for the backend |
| backend.storage | object | `{}` | Configures a persistent volume for the backend |
| dataStorage | object | `{}` | Configuration for data storage |
| dataStorage.accessMode | string | `"ReadWriteOnce"` | Access Mode of the storage device being used for the PVC |
| dataStorage.enabled | bool | `false` | Enable or disable data storage components. |
| dataStorage.mountPath | string | `"/app/data"` | Location where the PVC will be mounted. |
| dataStorage.size | string | `"10Gi"` | Size of the PVC created |
| dataStorage.storageClass | string | `nil` | Name of the storage class to use. If null it will use the configured default Storage Class. |
| frontend | object | `{}` | Configuration for the frontend |
| frontend.configEnvs | list | `[]` | configEnvs create ConfigMaps that are passed to containers using envFrom |
| frontend.configMounts | list | `[]` | volumeMounts to be added as configMaps. Requires matching configs. |
| frontend.configs | list | `[]` | Create `ConfigMap` resources that are projected through volumes. Must set matching configMounts. |
| frontend.enabled | bool | `true` | Enable or disable frontend components. |
| frontend.extraEnvVars | list | `[]` | List of extra environment variables that are set literally. |
| frontend.image.registry | string | `"docker.io"` | Image default registry |
| frontend.image.repository | string | `"nginxinc/nginx-unprivileged"` | Image default repository |
| frontend.image.tag | string | `"1.25-alpine"` | Image default tag |
| frontend.includeConfigAnnotation | bool | `false` | Add a checksum annotation to the server pods that is a hash    of the configuration. Can be used to identify configuration changes. |
| frontend.livenessProbe.enabled | bool | `false` | Enables livenessProbe |
| frontend.name | string | `""` | The name of the frontend container to create. If empty uses "frontend" |
| frontend.port | int | `8080` | Port on which the frontend is listening |
| frontend.pullPolicy | string | `"IfNotPresent"` | Frontend image pull policy |
| frontend.readinessProbe.enabled | bool | `false` | Enables readinessProbe |
| frontend.resources.limits | object | `{"cpu":"250m","memory":"256Mi"}` | Resource limits mapped directly to the value of    the resources field for a PodSpec. |
| frontend.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Resource requests mapped directly to the value of    the resources field for a PodSpec. |
| frontend.secretMounts | list | `[]` | volumeMounts to be added as secrets |
| frontend.securityContext | object | `{}`<br> | Security context for the pod template and the app container<br> Pod-level defaults:<br>   &nbsp;&nbsp;runAsNonRoot: true<br>   &nbsp;&nbsp;runAsGroup: 101<br>   &nbsp;&nbsp;runAsUser: 101<br>   &nbsp;&nbsp;fsGroup: 101<br>   &nbsp;&nbsp;readOnlyRootFilesystem: true<br>   &nbsp;&nbsp;allowPrivilegeEscalation: false<br>  Container-level defaults:<br> &nbsp;&nbsp;capabilities:<br> &nbsp;&nbsp;&nbsp;&nbsp;drop:<br> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;- ALL<br> |
| frontend.startupProbe.enabled | bool | `false` | Enables startupProbe |
| frontend.volumeMounts | list | `[]` | volumeMounts for the frontend container that also create corresponding `emptyDir` volumes in the pod. |
| global.imagePullSecrets | list | `[]` |  |
| global.name | string | `"qcon-guide"` | Authoritative name |
| global.progressDeadlineSeconds | int | `600` |  |
| global.revisionHistoryLimit | int | `3` |  |
| ingress | object | `{}` | Creates an ingress for external access |
| ingress.annotations | object | `{}` | Extra annotations to attach to the ingress resource |
| ingress.enabled | bool | `false` | Enable or disable ingress components. |
| ingress.extraLabels | object | `{}` | Extra labels to attach to the processor pods    Should be a YAML map of the labels to apply to the deployment template |
| ingress.extraPaths | list | `[]` | Extra paths to include in the ingress |
| ingress.hosts | list | `[]` | Ingress host definitions |
| ingress.ingressClassName | string | `""` | Default IngressClass to use. If empty, use the cluster's default |
| ingress.pathType | string | `"Prefix"` | Ingress pathType |
| ingress.tls | list | `[]` | TLS configuration for the ingress |
| processor | object | `{}` | Processor configuration |
| processor.configEnvs | list | `[]` | Create `ConfigMap` resources that are passed to containers using envFrom |
| processor.configMounts | list | `[]` | volumeMounts to be added as configMaps. Requires matching configs. |
| processor.configs | list | `[]` | Create `ConfigMap` resources that are projected through volumes. Must set matching configMounts. |
| processor.enabled | bool | `false` | Enable or disable processor components. |
| processor.extraEnvVars | list | `[]` | List of extra environment variables that are set literally. |
| processor.extraLabels | object | `{}` | Extra labels to attach to the processor pods    Should be a YAML map of the labels to apply to the deployment template |
| processor.image.registry | string | `""` | Image default registry |
| processor.image.repository | string | `""` | Image default repository |
| processor.image.tag | string | `""` | Image default tag |
| processor.replicas | int | `1` | Number of replicas for the processor |
| processor.secretMounts | list | `[]` | volumeMounts to be added as secrets |
| processor.volumeMounts | list | `[]` | volumeMounts for the processor container that also create corresponding emptyDir volumes in the pod. |
| service | object | `{}` | Enables a service for the processor app |
| service.enabled | bool | `false` | Enable or disable service components. |
| service.port | int | `8080` | Port on which the app is listening |
| service.type | string | `"ClusterIP"` | Service type: by default, connect to the app using an internal cluster IP |
| serviceAccount | object | `{}` | Configuration for the service account |
| serviceAccount.create | bool | `false` | Enable or disable service account creation. |
| serviceAccount.createSecret | bool | `true` | Create a Secret API object to store a non-expiring token for the service account. |
| serviceAccount.name | string | `""` | Name of the service account to create. If empty uses global.name |

## Building/updating README.md

```console
docker run -it --volume "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:latest helm-docs --template-files=./files/_README.md.gotmpl
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
