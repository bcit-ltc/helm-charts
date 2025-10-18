{{/*
SPDX-License-Identifier: MPL-2.0
Common helpers for LTC app charts
*/}}


{{/* ---------------------------------
     Identity & Labels
   --------------------------------- */}}

{{- define "apps-common.app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "apps-common.app.name" -}}
{{- default .Values.global.name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "apps-common.app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "apps-common.app.name" . }}
{{- end -}}

{{- define "apps-common.app.labels" -}}
helm.sh/chart: {{ include "apps-common.app.chart" . }}
app.kubernetes.io/name: {{ include "apps-common.app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end -}}


{{/* ---------------------------------
     imagePullSecrets
   --------------------------------- */}}
{{- define "apps-common.imagePullSecrets" -}}
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


{{/* ---------------------------------
     ServiceAccount helpers
   --------------------------------- */}}
{{- define "apps-common.app.serviceAccount.name" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "apps-common.app.name" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}


{{/* ---------------------------------
     Probes (liveness/readiness/startup)
   --------------------------------- */}}
{{/*
  apps-common.app.probe
  Input: a probe map (e.g., .Values.frontend.livenessProbe)
  Behavior:
    - If .enabled is false or empty -> emit nothing
    - If .execCommand has entries  -> use exec
    - Else                         -> use httpGet with .path and .port
    - Applies sane defaults if fields are missing
*/}}
{{- define "apps-common.app.probe" -}}
{{- $p := (default dict .) -}}
{{- if $p.enabled }}
  {{- if gt (len ($p.execCommand | default list)) 0 }}
exec:
  command:
  {{- range $p.execCommand }}
  - {{ . | quote }}
  {{- end }}
  {{- else }}
httpGet:
  path: {{ $p.path | default "/" | quote }}
  port: {{ $p.port | default 8080 }}
  {{- /* add scheme/headers here if you ever need them */ -}}
  {{- end }}
failureThreshold: {{ $p.failureThreshold     | default 3 }}
initialDelaySeconds: {{ $p.initialDelaySeconds | default 0 }}
periodSeconds: {{ $p.periodSeconds          | default 10 }}
successThreshold: {{ $p.successThreshold     | default 1 }}
timeoutSeconds: {{ $p.timeoutSeconds        | default 1 }}
{{- end -}}
{{- end -}}

{{/*
  apps-common.app.containerProbes
  Input: dict{"component": <.Values.frontend|.Values.processor>}
  Emits the three probe blocks if enabled.
*/}}
{{- define "apps-common.app.containerProbes" -}}
{{- $c := (get . "component") | default dict -}}
{{- with $c.livenessProbe }}
  {{- if .enabled }}
livenessProbe:
{{ include "apps-common.app.probe" . | nindent 2 }}
  {{- end }}
{{- end }}
{{- with $c.readinessProbe }}
  {{- if .enabled }}
readinessProbe:
{{ include "apps-common.app.probe" . | nindent 2 }}
  {{- end }}
{{- end }}
{{- with $c.startupProbe }}
  {{- if .enabled }}
startupProbe:
{{ include "apps-common.app.probe" . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}


{{/* ---------------------------------
     Annotations passthroughs
   --------------------------------- */}}
{{- define "apps-common.app.annotations.block" -}}
{{- $src := index . 0 -}}
{{- $extra := index . 1 | default (dict) -}}
{{- if or $src (gt (len $extra) 0) }}
annotations:
  {{- if $src }}
    {{- $tp := typeOf $src }}
    {{- if eq $tp "string" }}
{{ tpl $src $ | nindent 2 }}
    {{- else }}
{{ toYaml $src | nindent 2 }}
    {{- end }}
  {{- end }}
  {{- range $k, $v := $extra }}
  {{ $k }}: {{ $v | quote }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* Deployment annotations */}}
{{- define "apps-common.app.deployment.annotations" -}}
{{ include "apps-common.app.annotations.block" (list .Values.frontend.annotations (dict)) }}
{{- end -}}

{{/* Pod annotations (includes optional config checksums) */}}
{{- define "apps-common.app.pod.annotations" -}}
{{- $p := include "apps-common.app.componentConfigChecksum" .Values.processor -}}
{{- $f := include "apps-common.app.componentConfigChecksum" .Values.frontend  -}}
{{- $extra := dict -}}
{{- if $p }}{{- $_ := set $extra "checksum/processor-config" $p -}}{{- end -}}
{{- if $f }}{{- $_ := set $extra "checksum/frontend-config"  $f -}}{{- end -}}
{{ include "apps-common.app.annotations.block" (list .Values.frontend.annotations $extra) }}
{{- end -}}

{{/* Service annotations */}}
{{- define "apps-common.app.service.annotations" -}}
{{ include "apps-common.app.annotations.block" (list .Values.service.annotations (dict)) }}
{{- end -}}

{{/* Ingress annotations */}}
{{- define "apps-common.app.ingress.annotations" -}}
{{ include "apps-common.app.annotations.block" (list .Values.ingress.annotations (dict)) }}
{{- end -}}

{{/* ServiceAccount annotations */}}
{{- define "apps-common.app.serviceAccount.annotations" -}}
{{ include "apps-common.app.annotations.block" (list .Values.serviceAccount.annotations (dict)) }}
{{- end -}}

{{/* Volume annotations */}}
{{- define "apps-common.app.dataStorage.annotations" -}}
{{ include "apps-common.app.annotations.block" (list .Values.dataStorage.annotations (dict)) }}
{{- end -}}

{{/* Config checksum */}}
{{- define "apps-common.app.componentConfigChecksum" -}}
{{- $c := (default dict .) -}}
{{- $include := (get $c "includeConfigAnnotation") | default false -}}
{{- if $include -}}
  {{- $parts := list -}}
  {{- range ($c.configs | default list) }}{{- $parts = append $parts (toYaml .) }}{{- end }}
  {{- range ($c.configEnvs | default list) }}{{- $parts = append $parts (toYaml .) }}{{- end }}
  {{- if gt (len $parts) 0 -}}{{- join "\n---\n" $parts | sha256sum -}}{{- end -}}
{{- end -}}
{{- end -}}


{{/* ---------------------------------
     SecurityContext helpers
   --------------------------------- */}}
{{- define "apps-common.app.pod.securityContext" -}}
{{- $sc := (default dict .Values.securityContext) -}}
{{- if and (hasKey $sc "pod") (eq (get $sc "pod") nil) -}}
  {{- /* Explicitly disabled by user: .Values.securityContext.pod: null -> emit nothing */ -}}
{{- else -}}
  {{- $pod := (default dict (get $sc "pod")) -}}
  {{- $base := dict
        "runAsNonRoot" true
        "runAsUser"    101
        "runAsGroup"   101
        "fsGroup"      101
  -}}
  {{- toYaml (mergeOverwrite $base $pod) -}}
{{- end -}}
{{- end -}}

{{- define "apps-common.app.container.securityContext" -}}
{{- $root := index . "root" -}}
{{- $comp := (index . "component" | default dict) -}}
{{- $scComp := (default dict (get $comp "securityContext")) -}}
{{- if and (hasKey $scComp "container") (eq (get $scComp "container") nil) -}}
  {{- /* Explicitly disabled by user: <component>.securityContext.container: null -> emit nothing */ -}}
{{- else -}}
  {{- $scGlobal := (default dict $root.Values.securityContext) -}}
  {{- $global := (default dict (get $scGlobal "container")) -}}
  {{- $compC  := (default dict (get $scComp "container")) -}}
  {{- $base := dict
        "allowPrivilegeEscalation" false
        "readOnlyRootFilesystem"   true
        "capabilities" (dict "drop" (list "ALL"))
  -}}
  {{- toYaml (mergeOverwrite $base $global $compC) -}}
{{- end -}}
{{- end -}}


{{/* ---------------------------------
     Env & Mounts
   --------------------------------- */}}
{{- define "apps-common.app.extraEnvironmentVars" -}}
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

{{- define "apps-common.app.componentEnvFrom" -}}
{{- $c := . -}}
{{- range $cfg := ($c.configEnvs | default list) }}
- configMapRef:
    name: {{ $cfg.name | quote }}
{{- end }}
{{- end -}}

{{/* Secrets volume name is per-component: "<componentKey>-secrets" */}}
{{- define "apps-common.app.componentSecrets.volumeName" -}}
{{- $key := (get . "componentKey") | default "component" -}}
{{- printf "%s-secrets" $key | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  app.componentVolumeMounts
  Inputs: dict{"root": ., "component": <.Values.frontend|.Values.processor>, "componentKey": "frontend"|"processor"}
  Emits mounts for:
    * configMounts   -> per-item mount
    * emptyDirMounts -> per-item mount
    * storageMounts  -> per-item mount (PVC-backed)
    * secretMounts   -> single readOnly mount using "<componentKey>-secrets" at first mountPath (default /etc/secrets)
*/}}
{{- define "apps-common.app.componentVolumeMounts" -}}
{{- $root := (get . "root") -}}
{{- $c := (get . "component") | default dict -}}
{{- $key := (get . "componentKey") | default "component" -}}
{{- $out := list -}}

{{- range $m := ($c.configMounts | default list) }}
{{- $out = append $out (printf "- name: %q\n  mountPath: %q%s" $m.name $m.mountPath (ternary (printf "\n  subPath: %v" $m.subPath) "" (hasKey $m "subPath"))) -}}
{{- end }}

{{- range $m := ($c.emptyDirMounts | default list) }}
{{- $out = append $out (printf "- name: %q\n  mountPath: %q" $m.name $m.mountPath) -}}
{{- end }}

{{- range $m := ($c.storageMounts | default list) }}
{{- $out = append $out (printf "- name: %q\n  mountPath: %q" $m.name $m.mountPath) -}}
{{- end }}

{{- $sms := ($c.secretMounts | default list) -}}
{{- if gt (len $sms) 0 -}}
  {{- $mp := (index $sms 0).mountPath | default "/etc/secrets" -}}
  {{- $out = append $out (printf "- name: %q\n  mountPath: %q\n  readOnly: true" (include "apps-common.app.componentSecrets.volumeName" (dict "componentKey" $key)) $mp) -}}
{{- end }}

{{- if gt (len $out) 0 }}
{{- range $out }}
{{ . }}
{{- end }}
{{- end }}
{{- end -}}


{{/* ---------------------------------
     Volumes
   --------------------------------- */}}
{{/*
  app.componentConfigMapVolumes
  Inputs: dict{"component": <.Values.frontend|.Values.processor>}
  - Emits one configMap volume per configMounts item.
*/}}
{{- define "apps-common.app.componentConfigMapVolumes" -}}
{{- $c := (get . "component") | default dict -}}
{{- range $m := ($c.configMounts | default list) }}
- name: {{ $m.name | quote }}
  configMap:
    name: {{ $m.name | quote }}
{{- end }}
{{- end -}}

{{/*
  app.componentEmptyDirVolumes
  Inputs: dict{"component": <.Values.frontend|.Values.processor>}
  - Emits one emptyDir volume per emptyDirMounts item.
*/}}
{{- define "apps-common.app.componentEmptyDirVolumes" -}}
{{- $c := (get . "component") | default dict -}}
{{- range $m := ($c.emptyDirMounts | default list) }}
- name: {{ $m.name | quote }}
  emptyDir: {}
{{- end }}
{{- end -}}

{{/*
  app.componentSecrets.volume
  Inputs: dict{"root": ., "component": <.Values.frontend|.Values.processor>, "componentKey": "frontend"|"processor"}
  - Emits a single projected volume named "<componentKey>-secrets" aggregating all secretMounts entries.
*/}}
{{- define "apps-common.app.componentSecrets.volume" -}}
{{- $root := (get . "root") -}}
{{- $c := (get . "component") | default dict -}}
{{- $key := (get . "componentKey") | default "component" -}}
{{- $sms := ($c.secretMounts | default list) -}}
{{- if gt (len $sms) 0 }}
- name: {{ include "apps-common.app.componentSecrets.volumeName" (dict "componentKey" $key) | quote }}
  projected:
    sources:
    {{- range $s := $sms }}
      - secret:
          name: {{ $s.secretName | quote }}
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
    {{- end }}
{{- end }}
{{- end -}}

{{- define "apps-common.app.volumes" -}}
{{- $seen := dict -}}
{{- $chunks := list -}}
{{- $components := list (dict "key" "frontend" "c" .Values.frontend) (dict "key" "processor" "c" .Values.processor) -}}

{{- range $e := $components }}
  {{- $c := $e.c | default dict -}}

  {{- range $m := ($c.configMounts | default list) }}
    {{- $n := toString $m.name -}}
    {{- if not (hasKey $seen $n) -}}
      {{- $_ := set $seen $n true -}}
      {{- $chunks = append $chunks (printf "- name: %q\n  configMap:\n    name: %q" $n $n) -}}
    {{- end -}}
  {{- end }}

  {{- range $m := ($c.emptyDirMounts | default list) }}
    {{- $n := toString $m.name -}}
    {{- if not (hasKey $seen $n) -}}
      {{- $_ := set $seen $n true -}}
      {{- $chunks = append $chunks (printf "- name: %q\n  emptyDir: {}" $n) -}}
    {{- end -}}
  {{- end }}

  {{- range $m := ($c.storageMounts | default list) }}
    {{- $n := toString $m.name -}}
    {{- if not (hasKey $seen $n) -}}
      {{- $_ := set $seen $n true -}}
      {{- $chunks = append $chunks (printf "- name: %q\n  persistentVolumeClaim:\n    claimName: %q" $n $n) -}}
    {{- end -}}
  {{- end }}

  {{- $sms := ($c.secretMounts | default list) -}}
  {{- if gt (len $sms) 0 -}}
    {{- $vn := printf "%s-secrets" $e.key -}}
    {{- if not (hasKey $seen $vn) -}}
      {{- $_ := set $seen $vn true -}}
      {{- $buf := list (printf "- name: %q\n  projected:\n    sources:" $vn) -}}
      {{- range $s := $sms }}
        {{- $buf = append $buf (printf "      - secret:\n          name: %q" $s.secretName) -}}
        {{- with $s.items }}
          {{- $buf = append $buf "          items:" -}}
          {{- range . }}
            {{- $buf = append $buf (printf "            - key: %q\n              path: %q" .key .path) -}}
          {{- end }}
        {{- end }}
        {{- if hasKey $s "optional" }}
          {{- $buf = append $buf (printf "          optional: %v" $s.optional) -}}
        {{- end }}
      {{- end }}
      {{- $chunks = append $chunks (join "\n" $buf) -}}
    {{- end -}}
  {{- end }}
{{- end }}

{{- if gt (len $chunks) 0 -}}
{{- join "\n" $chunks -}}
{{- end -}}
{{- end -}}


{{/* ---------------------------------
     Persistent Storage (PVC)
   --------------------------------- */}}
{{- define "apps-common.app.dataStorage.volumeName" -}}
{{- printf "%s-data" (include "apps-common.app.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "apps-common.app.dataStorage.podVolume" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled }}
- name: {{ include "apps-common.app.dataStorage.volumeName" . }}
  persistentVolumeClaim:
    claimName: {{ include "apps-common.app.dataStorage.volumeName" . }}
{{- end -}}
{{- end -}}

{{- define "apps-common.app.dataStorage.processorVolumeMount" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled .Values.dataStorage.mountPath }}
- name: {{ include "apps-common.app.dataStorage.volumeName" . }}
  mountPath: {{ .Values.dataStorage.mountPath | quote }}
{{- end -}}
{{- end -}}

{{- define "apps-common.app.dataStorage.frontendVolumeMount" -}}
{{- if and .Values.dataStorage .Values.dataStorage.enabled .Values.dataStorage.mountPath }}
- name: {{ include "apps-common.app.dataStorage.volumeName" . }}
  mountPath: {{ .Values.dataStorage.mountPath | quote }}
{{- end -}}
{{- end -}}
