{{/*
SPDX-License-Identifier: MPL-2.0
*/}}

{{- define "apps-common.ingress.render" -}}
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "apps-common.app.name" . }}
  labels:
{{ include "apps-common.app.labels" . | nindent 4 }}
  {{- with (include "apps-common.app.ingress.annotations" .) }}
{{ . | nindent 2 }}
  {{- end }}
spec:
  {{- with .Values.ingress.ingressClassName }}
  ingressClassName: {{ . | quote }}
  {{- end }}
  rules:
    - host: {{ default (printf "%s.%s" .Values.global.name .Values.ingress.defaultDomain) .Values.ingress.host | quote }}
      http:
        paths:
          {{- range $p := (.Values.ingress.extraPaths | default list) }}
          - path: {{ $p.path }}
            pathType: {{ $p.pathType }}
            backend:
{{ toYaml $p.backend | nindent 14 }}
          {{- end }}
          - path: /
            pathType: {{ default "Prefix" .Values.ingress.pathType }}
            backend:
              service:
                name: {{ include "apps-common.app.name" . }}
                port:
                  number: {{ .Values.service.port }}
  {{- with .Values.ingress.tlsSecret }}
  tls:
    - secretName: {{ . | quote }}
      hosts:
        - {{ default (printf "%s.%s" $.Values.global.name $.Values.ingress.defaultDomain) $.Values.ingress.host | quote }}
  {{- end }}
{{- end }}
{{- end -}}
