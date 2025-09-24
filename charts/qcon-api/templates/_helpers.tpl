{{/*
SPDX-License-Identifier: MPL-2.0
*/}}

{{/* Chart label: <name>-<version> (with + replaced) */}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* App name: prefer global.name, fallback to chart name */}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.global.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* ServiceAccount flags (processor) */}}
{{- define "app.processorServiceAccountEnabled" -}}
{{- $_ := set . "processorServiceAccountEnabled" (eq (.Values.serviceAccount.create | toString) "true") -}}
{{- end -}}

{{- define "app.processorServiceAccountSecretCreationEnabled" -}}
{{- $_ := set . "processorServiceAccountSecretCreationEnabled" (and (eq (.Values.serviceAccount.create | toString) "true") (eq (.Values.serviceAccount.createSecret | toString) "true")) -}}
{{- end -}}

{{/* ServiceAccount name */}}
{{- define "app.serviceAccount.name" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "app.name" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/* Enablement flags */}}
{{- define "app.processorEnabled" -}}
{{- $p := (index .Values "processor" "enabled") | default "-" -}}
{{- $enabled := or (eq (toString $p) "true") (and (eq (toString $p) "-") (eq (.Values.global.enabled | toString) "true")) -}}
{{- $_ := set . "processorEnabled" $enabled -}}
{{- end -}}

{{- define "app.serviceEnabled" -}}
{{- template "app.processorEnabled" . -}}
{{- $_ := set . "serviceEnabled" (and .processorEnabled (eq (.Values.service.enabled | toString) "true")) -}}
{{- end -}}

{{/* ServiceAccount annotations */}}
{{- define "app.serviceAccount.annotations" -}}
{{- with .Values.serviceAccount.annotations }}
annotations:
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Deployment annotations (from processor.annotations) */}}
{{- define "app.deployment.annotations" -}}
{{- with .Values.processor.annotations }}
annotations:
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Ingress & Service annotations passthrough */}}
{{- define "app.ingress.annotations" -}}
{{- with .Values.ingress.annotations }}
annotations:
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "app.service.annotations" -}}
{{- with .Values.service.annotations }}
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Literal env vars (pass a component object, e.g., .Values.processor) */}}
{{- define "app.extraEnvironmentVars" -}}
{{- $c := . -}}
{{- if $c.extraEnvVars -}}
  {{- if kindIs "map" $c.extraEnvVars }}
    {{- range $key, $value := $c.extraEnvVars }}
- name: {{ printf "%s" $key | replace "." "_" | upper | quote }}
  value: {{ $value | quote }}
    {{- end }}
  {{- else }}
    {{- range $c.extraEnvVars }}
      {{- range $key, $value := . }}
- name: {{ printf "%s" $key | replace "." "_" | upper | quote }}
  value: {{ $value | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}
{{- end -}}

{{/* VolumeMounts per component (order: secretMounts, configMounts, volumeMounts) */}}
{{- define "app.componentVolumeMounts" -}}
{{- $c := . -}}
{{- range $m := ($c.secretMounts | default list) }}
- name: {{ $m.name | quote }}
  mountPath: {{ $m.mountPath | quote }}
  {{- if hasKey $m "readOnly" }}
  readOnly: {{ $m.readOnly }}
  {{- end }}
{{- end }}
{{- range $m := ($c.configMounts | default list) }}
- name: {{ $m.name | quote }}
  mountPath: {{ $m.mountPath | quote }}
{{- end }}
{{- range $m := ($c.volumeMounts | default list) }}
- name: {{ $m.name | quote }}
  mountPath: {{ $m.mountPath | quote }}
{{- end }}
{{- end -}}

{{/* envFrom per component (supports both configs and configEnvs) */}}
{{- define "app.componentEnvFrom" -}}
{{- $c := . -}}
{{- range $cfg := ($c.configs | default list) }}
- configMapRef:
    name: {{ $cfg.name | quote }}
{{- end }}
{{- range $cfg := ($c.configEnvs | default list) }}
- configMapRef:
    name: {{ $cfg.name | quote }}
{{- end }}
{{- end -}}

{{/* Pod volumes (from mounts only). Dedupe by name. */}}
{{- define "app.podVolumes" -}}
{{- $seen := dict -}}
{{- $components := list .Values.processor .Values.frontend .Values.backend -}}

{{- range $c := $components }}
  {{- range $m := ($c.volumeMounts | default list) }}
  {{- if not (hasKey $seen $m.name) }}
- name: {{ $m.name | quote }}
  emptyDir: {}
  {{- $_ := set $seen $m.name true }}
  {{- end }}
  {{- end }}
  {{- range $m := ($c.configMounts | default list) }}
  {{- if not (hasKey $seen $m.name) }}
- name: {{ $m.name | quote }}
  configMap:
    name: {{ $m.name | quote }}
  {{- $_ := set $seen $m.name true }}
  {{- end }}
  {{- end }}
  {{- range $s := ($c.secretMounts | default list) }}
  {{- if not (hasKey $seen $s.name) }}
- name: {{ $s.name | quote }}
  secret:
    secretName: {{ $s.secretName | quote }}
    {{- with $s.items }}
    items:
      {{- range . }}
      - key: {{ .key | quote }}
        path: {{ .path | quote }}
      {{- end }}
    {{- end }}
    {{- if hasKey $s "optional" }}
    optional: {{ $s.optional }}
    {{- end }}
  {{- $_ := set $seen $s.name true }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Frontend annotations passthrough (kept minimal) */}}
{{- define "app.annotations" -}}
{{- with .Values.frontend.annotations }}
annotations:
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* imagePullSecrets from global.imagePullSecrets */}}
{{- define "imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- range . }}
    {{- if typeIs "string" . }}
  - name: {{ . }}
    {{- else if index . "name" }}
  - name: {{ .name }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Frontend helpers used in deployment.yaml */}}
{{- define "frontend.resources" -}}
{{- with .Values.frontend.resources }}
resources:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "frontend.securityContext.pod" -}}
  {{- if .Values.frontend.securityContext.pod }}
securityContext:
  {{- $tp := typeOf .Values.frontend.securityContext.pod }}
  {{- if eq $tp "string" }}
{{ tpl .Values.frontend.securityContext.pod . | nindent 2 }}
  {{- else }}
{{ toYaml .Values.frontend.securityContext.pod | nindent 2 }}
  {{- end }}
  {{- else }}
securityContext:
  runAsNonRoot: {{ .Values.frontend.securityContext.runAsNonRoot | default true }}
  runAsGroup: {{ .Values.frontend.securityContext.runAsGroup | default 101 }}
  runAsUser: {{ .Values.frontend.securityContext.runAsUser | default 101 }}
  fsGroup: {{ .Values.frontend.securityContext.fsGroup | default 1000 }}
  seccompProfile:
    type: RuntimeDefault
  {{- end }}
{{- end -}}

{{- define "frontend.securityContext.container" -}}
  {{- if .Values.frontend.securityContext.container }}
securityContext:
  {{- $tp := typeOf .Values.frontend.securityContext.container }}
  {{- if eq $tp "string" }}
{{ tpl .Values.frontend.securityContext.container . | nindent 2 }}
  {{- else }}
{{ toYaml .Values.frontend.securityContext.container | nindent 2 }}
  {{- end }}
  {{- else }}
securityContext:
  readOnlyRootFilesystem: {{ .Values.frontend.securityContext.readOnlyRootFilesystem | default true }}
  allowPrivilegeEscalation: {{ .Values.frontend.securityContext.allowPrivilegeEscalation | default false }}
  capabilities:
    drop:
      - ALL
  {{- end }}
{{- end -}}
