{{/*
SPDX-License-Identifier: MPL-2.0
Local chart helpers
*/}}

{{- define "haproxy-operator.name" -}}
{{- include "apps-common.app.name" . -}}
{{- end -}}

{{- define "haproxy-operator.serviceAccountName" -}}
{{- include "apps-common.app.serviceAccount.name" . -}}
{{- end -}}

{{- define "haproxy-operator.rbacName" -}}
{{- printf "%s" (include "apps-common.app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Image rendering
Uses .Values.processor.image (apps-common convention)
*/}}
{{- define "haproxy-operator.image" -}}
{{- $img := (default dict .Values.processor.image) -}}
{{- $registry := (default "" $img.registry) -}}
{{- $repository := (default "" $img.repository) -}}
{{- $tag := (default "" $img.tag) -}}
{{- if and (ne $registry "") (ne $repository "") -}}
{{- printf "%s/%s:%s" $registry $repository ($tag | default .Chart.AppVersion) -}}
{{- else if ne $repository "" -}}
{{- printf "%s:%s" $repository ($tag | default .Chart.AppVersion) -}}
{{- else -}}
{{- fail "No image repository configured (set processor.image.repository)" -}}
{{- end -}}
{{- end -}}

{{- define "haproxy-operator.imagePullPolicy" -}}
{{- $img := (default dict .Values.processor.image) -}}
{{- default "IfNotPresent" $img.pullPolicy -}}
{{- end -}}
