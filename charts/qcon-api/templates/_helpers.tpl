{{/*
SPDX-License-Identifier: MPL-2.0
*/}}

{{/* Chart label: <name>-<version> (with + replaced) */}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* App name: prefer .Values.global.name, fallback to chart name */}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.global.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* ----------------------------
     ServiceAccount helpers
   ---------------------------- */}}
{{/* SA create: default TRUE unless explicitly set */}}
{{- define "app.processorServiceAccountEnabled" -}}
{{- $create := ternary .Values.serviceAccount.create true (hasKey .Values.serviceAccount "create") -}}
{{- $_ := set . "processorServiceAccountEnabled" $create -}}
{{- end -}}

{{/* SA token Secret: only if SA create is enabled AND createSecret is explicitly true (default FALSE) */}}
{{- define "app.processorServiceAccountSecretCreationEnabled" -}}
{{- $create := ternary .Values.serviceAccount.create true (hasKey .Values.serviceAccount "create") -}}
{{- $createSecret := ternary .Values.serviceAccount.createSecret false (hasKey .Values.serviceAccount "createSecret") -}}
{{- $_ := set . "processorServiceAccountSecretCreationEnabled" (and $create $createSecret) -}}
{{- end -}}

{{/* ServiceAccount name */}}
{{- define "app.serviceAccount.name" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "app.name" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/* ----------------------------
     Enablement flags
   ---------------------------- */}}
{{/* Whether processor is enabled (defaults to false if unset) */}}
{{- define "app.processorEnabled" -}}
{{- $_ := set . "processorEnabled" (default false .Values.processor.enabled) -}}
{{- end -}}

{{/* Whether service is enabled (defaults to false if unset) */}}
{{- define "app.serviceEnabled" -}}
{{- $_ := set . "serviceEnabled" (default false .Values.service.enabled) -}}
{{- end -}}

{{/* Whether frontend is enabled (defaults to false if unset) */}}
{{- define "app.frontendEnabled" -}}
{{- $_ := set . "frontendEnabled" (default false .Values.frontend.enabled) -}}
{{- end -}}

{{/* Whether backend is enabled (defaults to false if unset) */}}
{{- define "app.backendEnabled" -}}
{{- $_ := set . "backendEnabled" (default false .Values.backend.enabled) -}}
{{- end -}}

{{/* ----------------------------
     Annotation passthroughs
   ---------------------------- */}}
{{/* Pod template annotations passthrough (from frontend.annotations) */}}
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

{{/* Ingress annotations passthrough */}}
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

{{/* Service annotations passthrough */}}
{{- define "app.service.annotations" -}}
{{- with .Values.service.annotations }}
annotations:
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Optional: generic frontend annotations passthrough */}}
{{- define "app.frontend.annotations" -}}
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

{{/* ----------------------------
     Env & mounts
   ---------------------------- */}}
{{/* Literal env vars (supports list of one-key maps OR a flat map) */}}
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

{{/* envFrom per component: supports configs[] and configEnvs[] */}}
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

{{/* VolumeMounts per component (secretMounts -> configMounts -> volumeMounts) */}}
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
{{- $components := list .Values.processor .Values.frontend .Values.backend -}}

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

{{/* ----------------------------
     imagePullSecrets (from global.imagePullSecrets)
   ---------------------------- */}}
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
{{/* Name for the PVC and the pod volume */}}
{{- define "app.dataStorage.volumeName" -}}
{{- printf "%s-data" (include "app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.dataStorage.claimName" -}}
{{- include "app.dataStorage.volumeName" . -}}
{{- end -}}

{{/* Pod volume block for the PVC (used under spec.volumes) */}}
{{- define "app.dataStorage.podVolume" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled }}
- name: {{ include "app.dataStorage.volumeName" . }}
  persistentVolumeClaim:
    claimName: {{ include "app.dataStorage.claimName" . }}
{{- end -}}
{{- end -}}

{{/* VolumeMount for the processor container */}}
{{- define "app.dataStorage.processorVolumeMount" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled .Values.dataStorage.mountPath }}
- name: {{ include "app.dataStorage.volumeName" . }}
  mountPath: {{ .Values.dataStorage.mountPath | quote }}
{{- end -}}
{{- end -}}

{{/* VolumeMount for the frontend container */}}
{{- define "app.dataStorage.frontendVolumeMount" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled .Values.dataStorage.mountPath }}
- name: {{ include "app.dataStorage.volumeName" . }}
  mountPath: {{ .Values.dataStorage.mountPath | quote }}
{{- end -}}
{{- end -}}

{{/* VolumeMount for the backend container */}}
{{- define "app.dataStorage.backendVolumeMount" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled .Values.dataStorage.mountPath }}
- name: {{ include "app.dataStorage.volumeName" . }}
  mountPath: {{ .Values.dataStorage.mountPath | quote }}
{{- end -}}
{{- end -}}

{{/* ----------------------------
     Config checksum annotations
   ---------------------------- */}}
{{/* Hash a single component's configs + configEnvs; returns "" if none */}}
{{- define "app.componentConfigChecksum" -}}
{{- $c := . -}}
{{- $parts := list -}}
{{- range ($c.configs | default list) }}
  {{- $parts = append $parts (toYaml .) -}}
{{- end }}
{{- range ($c.configEnvs | default list) }}
  {{- $parts = append $parts (toYaml .) -}}
{{- end }}
{{- if gt (len $parts) 0 -}}
{{- join "\n---\n" $parts | sha256sum -}}
{{- end -}}
{{- end -}}

{{/* One annotations block merging frontend.annotations + checksums */}}
{{- define "app.pod.annotations" -}}
{{- $p := include "app.componentConfigChecksum" .Values.processor -}}
{{- $f := include "app.componentConfigChecksum" .Values.frontend -}}
{{- $b := include "app.componentConfigChecksum" .Values.backend -}}
{{- $hasChecks := or $p (or $f $b) -}}
{{- if or $hasChecks .Values.frontend.annotations }}
annotations:
  {{- with .Values.frontend.annotations }}
  {{- $tp := typeOf . }}
  {{- if eq $tp "string" }}
{{ tpl . $ | nindent 2 }}
  {{- else }}
{{ toYaml . | nindent 2 }}
  {{- end }}
  {{- end }}
  {{- if $p }}
  checksum/processor-config: {{ $p | quote }}
  {{- end }}
  {{- if $f }}
  checksum/frontend-config: {{ $f | quote }}
  {{- end }}
  {{- if $b }}
  checksum/backend-config: {{ $b | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* ----------------------------
     Frontend-specific passthroughs
   ---------------------------- */}}
{{- define "frontend.resources" -}}
{{- with .Values.frontend.resources }}
resources:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "frontend.securityContext.pod" -}}
{{- with .Values.frontend.securityContext.pod }}
securityContext:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "frontend.securityContext.container" -}}
{{- with .Values.frontend.securityContext.container }}
securityContext:
{{ toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
