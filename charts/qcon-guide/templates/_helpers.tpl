{{/* Alias helpers to library to keep callsites unchanged */}}
{{- define "app.annotations.block" -}}
{{ include "apps-common.app.annotations.block" . }}
{{- end -}}

{{- define "app.chart" -}}
{{ include "apps-common.app.chart" . }}
{{- end -}}

{{- define "app.componentConfigChecksum" -}}
{{ include "apps-common.app.componentConfigChecksum" . }}
{{- end -}}

{{- define "app.componentConfigMapVolumes" -}}
{{ include "apps-common.app.componentConfigMapVolumes" . }}
{{- end -}}

{{- define "app.componentEmptyDirVolumes" -}}
{{ include "apps-common.app.componentEmptyDirVolumes" . }}
{{- end -}}

{{- define "app.componentEnvFrom" -}}
{{ include "apps-common.app.componentEnvFrom" . }}
{{- end -}}

{{- define "app.componentSecrets.volume" -}}
{{ include "apps-common.app.componentSecrets.volume" . }}
{{- end -}}

{{- define "app.componentSecrets.volumeName" -}}
{{ include "apps-common.app.componentSecrets.volumeName" . }}
{{- end -}}

{{- define "app.componentVolumeMounts" -}}
{{ include "apps-common.app.componentVolumeMounts" . }}
{{- end -}}

{{- define "app.container.securityContext" -}}
{{ include "apps-common.app.container.securityContext" . }}
{{- end -}}

{{- define "app.dataStorage.annotations" -}}
{{ include "apps-common.app.dataStorage.annotations" . }}
{{- end -}}

{{- define "app.dataStorage.frontendVolumeMount" -}}
{{ include "apps-common.app.dataStorage.frontendVolumeMount" . }}
{{- end -}}

{{- define "app.dataStorage.podVolume" -}}
{{ include "apps-common.app.dataStorage.podVolume" . }}
{{- end -}}

{{- define "app.dataStorage.processorVolumeMount" -}}
{{ include "apps-common.app.dataStorage.processorVolumeMount" . }}
{{- end -}}

{{- define "app.dataStorage.volumeName" -}}
{{ include "apps-common.app.dataStorage.volumeName" . }}
{{- end -}}

{{- define "app.deployment.annotations" -}}
{{ include "apps-common.app.deployment.annotations" . }}
{{- end -}}

{{- define "app.extraEnvironmentVars" -}}
{{ include "apps-common.app.extraEnvironmentVars" . }}
{{- end -}}

{{- define "app.ingress.annotations" -}}
{{ include "apps-common.app.ingress.annotations" . }}
{{- end -}}

{{- define "app.labels" -}}
{{ include "apps-common.app.labels" . }}
{{- end -}}

{{- define "app.name" -}}
{{ include "apps-common.app.name" . }}
{{- end -}}

{{- define "app.pod.annotations" -}}
{{ include "apps-common.app.pod.annotations" . }}
{{- end -}}

{{- define "app.pod.securityContext" -}}
{{ include "apps-common.app.pod.securityContext" . }}
{{- end -}}

{{- define "app.selectorLabels" -}}
{{ include "apps-common.app.selectorLabels" . }}
{{- end -}}

{{- define "app.service.annotations" -}}
{{ include "apps-common.app.service.annotations" . }}
{{- end -}}

{{- define "app.serviceAccount.annotations" -}}
{{ include "apps-common.app.serviceAccount.annotations" . }}
{{- end -}}

{{- define "app.serviceAccount.name" -}}
{{ include "apps-common.app.serviceAccount.name" . }}
{{- end -}}

{{- define "app.volumes" -}}
{{ include "apps-common.app.volumes" . }}
{{- end -}}

{{- define "imagePullSecrets" -}}
{{ include "apps-common.imagePullSecrets" . }}
{{- end -}}

{{- define "app.ingress.render" -}}
{{ include "apps-common.ingress.render" . }}
{{- end -}}
