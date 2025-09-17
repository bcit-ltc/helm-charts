{{- define "app.name" -}}{{- .Chart.Name -}}{{- end }}

{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride }}{{- .Values.fullnameOverride -}}{{- else -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}

{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ include "app.fullname" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ include "app.fullname" . }}
{{- end }}

{{- define "app.image" -}}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) -}}
{{- end }}

{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccountName }}{{ .Values.serviceAccountName }}{{- else -}}{{ include "app.fullname" . }}{{- end -}}
{{- end }}
