{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "app.labels" -}}
{{- /* Build a label-safe chart version and chart label value */ -}}
{{- $chartVersionLabel := .Chart.Version
    | replace "+" "_"                             /* '+' not allowed in labels */
    | regexReplaceAll "[^A-Za-z0-9_.-]" "_"       /* keep only label-safe chars */
    | trunc 63
    | trimSuffix "-"
    | trimSuffix "_"
    | trimSuffix "."
-}}
{{- $helmChartLabel := (printf "%s-%s" .Chart.Name $chartVersionLabel)
    | trunc 63
    | trimSuffix "-"
    | trimSuffix "_"
    | trimSuffix "."
-}}
helm.sh/chart: {{ $helmChartLabel | quote }}

app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}

{{- /* app.kubernetes.io/version should also be label-safe; fall back to Chart.Version if AppVersion empty */ -}}
{{- $rawAppVer := default .Chart.Version .Chart.AppVersion -}}
{{- $appVersionLabel := $rawAppVer
    | replace "+" "_" 
    | regexReplaceAll "[^A-Za-z0-9_.-]" "_"
    | trunc 63
    | trimSuffix "-"
    | trimSuffix "_"
    | trimSuffix "."
-}}
app.kubernetes.io/version: {{ $appVersionLabel | quote }}
{{- end -}}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "app.image" -}}
{{- $registry := .Values.image.registry | default "" -}}
{{- if $registry -}}{{- printf "%s/%s:%s" $registry .Values.image.repository .Values.image.tag -}}
{{- else -}}{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}{{- end -}}
{{- end -}}

{{- define "app.serviceAccountName" -}}
{{- if and .Values.serviceAccount.create (not .Values.serviceAccount.name) -}}
{{ include "app.fullname" . }}
{{- else -}}
{{- default (include "app.fullname" .) .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}
