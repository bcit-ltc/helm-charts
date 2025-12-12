{{/*
SPDX-License-Identifier: MPL-2.0
*/}}

{{- define "apps-common.ingress.render" -}}
{{- if .Values.ingress.enabled }}

{{- $defaultDomain := "ltc.bcit.ca" -}}
{{- $domain := default $defaultDomain .Values.ingress.defaultDomain -}}

{{- $defaultTlsSecret := "star-ltc-bcit-ca" -}}
{{- $tlsVal := .Values.ingress.tlsSecret -}}
{{- $tlsSecret := ternary $defaultTlsSecret $tlsVal (eq $tlsVal "") -}}
# ^ If tlsSecret == "" → use library default
#   If tlsSecret is non-empty → use provided
#   If tlsSecret is null → handled later (omit TLS stanza)

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
    - host: {{ default (printf "%s.%s" .Values.global.name $domain) .Values.ingress.host | quote }}
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

  {{/* TLS HANDLING — OMIT IF NULL */}}
  {{- if not (eq $tlsVal nil) }}
  tls:
    - secretName: {{ $tlsSecret | quote }}
      hosts:
        - {{ default (printf "%s.%s" $.Values.global.name $domain) $.Values.ingress.host | quote }}
  {{- end }}

{{- end }}
{{- end -}}
