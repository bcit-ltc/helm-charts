{{/*
SPDX-License-Identifier: MPL-2.0
Common helpers for LTC app charts.
*/}}

{{/* Chart label: <name>-<version> (with + replaced) */}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* App name: prefer .Values.global.name, fallback to chart name */}}
{{- define "app.name" -}}
{{- default .Values.global.name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Selector labels */}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
{{- end -}}

{{/* Standard labels */}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}

{{/* ----------------------------
     ServiceAccount helpers
   ---------------------------- */}}
{{- define "app.serviceAccount.name" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "app.name" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/* ----------------------------
     Annotations passthroughs
   ---------------------------- */}}
{{- define "app.annotations.block" -}}
{{- $src := index . 0 -}}
{{- with $src }}
annotations:
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "app.deployment.annotations" -}}
{{ include "app.annotations.block" (list .Values.processor.annotations) }}
{{- end -}}

{{- define "app.pod.annotations" -}}
{{- $p := include "app.componentConfigChecksum" .Values.processor -}}
{{- $f := include "app.componentConfigChecksum" .Values.frontend  -}}
{{- $hasChecks := or $p $f -}}
{{- if or $hasChecks .Values.frontend.annotations }}
annotations:
  {{- with .Values.frontend.annotations }}
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}{{ tpl . $ | nindent 2 }}{{ else }}{{ toYaml . | nindent 2 }}{{ end }}
  {{- end }}
  {{- if $p }}checksum/processor-config: {{ $p | quote }}{{- end }}
  {{- if $f }}checksum/frontend-config:  {{ $f | quote }}{{- end }}
{{- end }}
{{- end -}}

{{- define "app.service.annotations" -}}
{{ include "app.annotations.block" (list .Values.service.annotations) }}
{{- end -}}

{{- define "app.ingress.annotations" -}}
{{ include "app.annotations.block" (list .Values.ingress.annotations) }}
{{- end -}}

{{- define "app.serviceAccount.annotations" -}}
{{ include "app.annotations.block" (list .Values.serviceAccount.annotations) }}
{{- end -}}

{{/* ----------------------------
     Env & mounts
   ---------------------------- */}}
{{- define "app.extraEnvironmentVars" -}}
{{- $c := . -}}
{{- if $c.extraEnvVars -}}
  {{- if kindIs "map" $c.extraEnvVars }}
    {{- range $k, $v := $c.extraEnvVars }}
- name: {{ printf "%s" $k | replace "." "_" | upper | quote }}
  value: {{ $v | quote }}
    {{- end }}
  {{- else }}
    {{- range $c.extraEnvVars }}
      {{- range $k, $v := . }}
- name: {{ printf "%s" $k | replace "." "_" | upper | quote }}
  value: {{ $v | quote }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end -}}
{{- end -}}

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

{{- define "app.componentVolumeMounts" -}}
{{- $c := . -}}
{{- range $m := ($c.secretMounts | default list) }}
- name: {{ $m.name | quote }}
  mountPath: {{ $m.mountPath | quote }}
{{- if hasKey $m "readOnly" }}
  readOnly: {{ $m.readOnly }}
{{- end }}
{{- if hasKey $m "subPath" }}
  subPath: {{ $m.subPath }}
{{- end }}
{{- end }}
{{- range $m := ($c.configMounts | default list) }}
- name: {{ $m.name | quote }}
  mountPath: {{ $m.mountPath | quote }}
{{- if hasKey $m "subPath" }}
  subPath: {{ $m.subPath }}
{{- end }}
{{- end }}
{{- range $m := ($c.volumeMounts | default list) }}
- name: {{ $m.name | quote }}
  mountPath: {{ $m.mountPath | quote }}
{{- if hasKey $m "readOnly" }}
  readOnly: {{ $m.readOnly }}
{{- end }}
{{- if hasKey $m "subPath" }}
  subPath: {{ $m.subPath }}
{{- end }}
{{- end }}
{{- end -}}


{{/* ----------------------------
     Volumes (dedup by name)
   ---------------------------- */}}
{{- define "app.podVolumes" -}}
{{- $seen := dict -}}
{{- $components := list .Values.processor .Values.frontend -}}
{{- range $c := $components }}
  {{- if $c }}
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
{{- end }}
{{- end -}}

{{/* imagePullSecrets from global */}}
{{- define "imagePullSecrets" -}}
{{- $ips := .Values.global.imagePullSecrets -}}
{{- if $ips }}
imagePullSecrets:
  {{- range $i := $ips }}
    {{- if typeIs "string" $i }}
  - name: {{ $i }}
    {{- else if (and (kindIs "map" $i) (hasKey $i "name")) }}
  - name: {{ $i.name }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* =========================
     Persistent Storage (PVC)
   ========================= */}}
{{- define "app.dataStorage.volumeName" -}}
{{- printf "%s-data" (include "app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.dataStorage.podVolume" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled }}
- name: {{ include "app.dataStorage.volumeName" . }}
  persistentVolumeClaim:
    claimName: {{ include "app.dataStorage.volumeName" . }}
{{- end -}}
{{- end -}}

{{- define "app.dataStorage.processorVolumeMount" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled .Values.dataStorage.mountPath }}
- name: {{ include "app.dataStorage.volumeName" . }}
  mountPath: {{ .Values.dataStorage.mountPath | quote }}
{{- end -}}
{{- end -}}

{{- define "app.dataStorage.frontendVolumeMount" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled .Values.dataStorage.mountPath }}
- name: {{ include "app.dataStorage.volumeName" . }}
  mountPath: {{ .Values.dataStorage.mountPath | quote }}
{{- end -}}
{{- end -}}

{{/* Config checksum */}}
{{- define "app.componentConfigChecksum" -}}
{{- $c := . -}}
{{- $parts := list -}}
{{- range ($c.configs | default list) }}{{- $parts = append $parts (toYaml .) }}{{- end }}
{{- range ($c.configEnvs | default list) }}{{- $parts = append $parts (toYaml .) }}{{- end }}
{{- if gt (len $parts) 0 -}}{{- join "\n---\n" $parts | sha256sum -}}{{- end -}}
{{- end -}}

{{/* Frontend defaults volumes (collision-safe) */}}
{{- define "app.defaultFrontendVolumes" -}}
{{- $present := dict "tmp" false "nginx-config" false -}}
{{- range $m := (default (list) .Values.frontend.volumeMounts) }}{{- if eq $m.name "tmp" }}{{- $_ := set $present "tmp" true }}{{- end }}{{- if eq $m.name "nginx-config" }}{{- $_ := set $present "nginx-config" true }}{{- end }}{{- end }}
{{- range $m := (default (list) .Values.frontend.configMounts) }}{{- if eq $m.name "tmp" }}{{- $_ := set $present "tmp" true }}{{- end }}{{- if eq $m.name "nginx-config" }}{{- $_ := set $present "nginx-config" true }}{{- end }}{{- end }}
{{- range $s := (default (list) .Values.frontend.secretMounts) }}{{- if eq $s.name "tmp" }}{{- $_ := set $present "tmp" true }}{{- end }}{{- if eq $s.name "nginx-config" }}{{- $_ := set $present "nginx-config" true }}{{- end }}{{- end }}
{{- if and (eq (len (default (list) .Values.frontend.volumeMounts)) 0) (not (get $present "tmp")) }}
- name: tmp
  emptyDir: {}
{{- end }}
{{- if and (eq (len (default (list) .Values.frontend.configMounts)) 0) (not (get $present "nginx-config")) }}
- name: nginx-config
  configMap:
    name: nginx-config
{{- end }}
{{- end -}}

{{/* =============================
     Security Context (defaults)
   ============================= */}}

{{/* Pod-level security context with defaults, overridable by:
     .Values.podSecurityContext OR .Values.frontend.securityContext.pod (for back-compat)
*/}}
{{- define "app.securityContext.pod" -}}
{{- $defaults := dict
      "runAsNonRoot" true
      "runAsUser"    101
      "runAsGroup"   101
      "fsGroup"      101
-}}
{{- $override := coalesce .Values.podSecurityContext .Values.frontend.securityContext.pod | default dict -}}
{{- $merged := mustMergeOverwrite (deepCopy $defaults) $override -}}
{{- if gt (len $merged) 0 -}}
{{ toYaml $merged }}
{{- end -}}
{{- end -}}

{{/* Container-level security context with defaults, overridable by passing a dict:
     include "app.securityContext.container" (dict "override" .Values.frontend.securityContext.container)
*/}}
{{- define "app.securityContext.container" -}}
{{- $defaults := dict
      "allowPrivilegeEscalation" false
      "readOnlyRootFilesystem"   true
      "capabilities" (dict "drop" (list "ALL"))
-}}
{{- $override := (.override | default dict) -}}
{{- $merged := mustMergeOverwrite (deepCopy $defaults) $override -}}
{{ toYaml $merged }}
{{- end -}}
