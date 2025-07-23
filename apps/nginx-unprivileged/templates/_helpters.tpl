{{/*
Expand the name of the chart.
*/}}
{{- define "nginx-unprivileged.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | lower -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "nginx-unprivileged.labels" -}}
{{ include "nginx-unprivileged.selectorLabels" . }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "nginx-unprivileged.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nginx-unprivileged.name" . }}
{{- end }}