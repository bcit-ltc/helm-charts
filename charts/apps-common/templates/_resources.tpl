{{/* =========================
   Service
   ========================= */}}
{{- define "apps-common.render.service" -}}
{{- if (default true .Values.service.enabled) }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "apps-common.app.name" . }}
  labels:
{{ include "apps-common.app.labels" . | nindent 4 }}
  {{ include "apps-common.app.service.annotations" . | nindent 2 }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  ports:
    - port: {{ .Values.service.port | default 8080 }}
      targetPort: {{ .Values.service.targetPort | default .Values.service.port }}
      protocol: TCP
      name: http
  selector:
{{ include "apps-common.app.selectorLabels" . | nindent 4 }}
{{- end }}
{{- end -}}

{{/* =========================
   ServiceAccount
   ========================= */}}
{{- define "apps-common.render.serviceaccount" -}}
{{- if (default true .Values.serviceAccount.create) }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "apps-common.app.name" . }}
  labels:
{{ include "apps-common.app.labels" . | nindent 4 }}
  {{ include "apps-common.app.serviceAccount.annotations" . | nindent 2 }}
{{- end }}
{{- end -}}

{{/* =========================
   PVCs (from storageMounts)
   ========================= */}}
{{- define "apps-common.render.pvcs" -}}
{{- $root := . -}}
{{- $components := list .Values.frontend .Values.processor -}}
{{- range $c := $components }}
  {{- range $m := ($c.storageMounts | default list) }}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $m.name | quote }}
  labels:
{{ include "apps-common.app.labels" $root | nindent 4 }}
spec:
  accessModes:
    - {{ ($m.accessMode | default "ReadWriteOnce") | quote }}
  resources:
    requests:
      storage: {{ $m.size | quote }}
  {{- with $m.storageClass }}
  storageClassName: {{ . | quote }}
  {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* =========================
   ConfigMaps (from configMounts)
   ========================= */}}
{{- define "apps-common.render.configmaps" -}}
{{- $root := . -}}
{{- $components := list .Values.frontend .Values.processor -}}
{{- range $c := $components }}
  {{- range $m := ($c.configMounts | default list) }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $m.name | quote }}
  labels:
{{ include "apps-common.app.labels" $root | nindent 4 }}
data:
{{- if $m.data }}
{{ toYaml $m.data | nindent 2 }}
{{- end }}
  {{- end }}
{{- end }}
{{- end -}}
