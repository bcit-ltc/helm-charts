{{/*
SPDX-License-Identifier: MPL-2.0
*/}}

{{- define "apps-common.assets.render" -}}
{{- if and .Values.assets .Values.assets.enabled }}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ printf "%s-populate-assets" (include "apps-common.app.name" .) | trunc 63 | trimSuffix "-" }}
  labels:
{{ include "apps-common.app.labels" . | nindent 4 }}
spec:
  ttlSecondsAfterFinished: 100
  template:
    metadata:
      labels:
{{ include "apps-common.app.labels" . | nindent 8 }}
    spec:
      restartPolicy: OnFailure
      {{- if .Values.assets.coLocateWithApp }}
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app.kubernetes.io/name: {{ include "apps-common.app.name" . | quote }}
              topologyKey: kubernetes.io/hostname
      {{- end }}

      containers:
        - name: oras
          image: "{{ .Values.assets.image.repository }}:{{ .Values.assets.image.tag }}"
          imagePullPolicy: {{ .Values.assets.image.pullPolicy | default "IfNotPresent" }}
          env:
            - name: ORAS_REF
              value: {{ required "values.assets.ref is required" .Values.assets.ref | quote }}
            - name: GITHUB_USER
              value: {{ .Values.assets.githubUser | default "github" | quote }}
            - name: GITHUB_PAT
              value: {{ .Values.assets.tokenPath | default "/etc/secrets/GITHUB_TOKEN" | quote }}
            # path inside the tarball
            - name: ASSET_SOURCE
              value: {{ .Values.assets.sourcePath | default "." | quote }}
            # path under /usr/share/nginx/html (PVC) where assets should land
            - name: ASSET_TARGET
              value: {{ .Values.assets.targetPath | default "." | quote }}
          resources:
{{ toYaml .Values.assets.resources | nindent 12 }}
          command: ["/bin/sh","-ceu"]
          args:
            - |
              REGISTRY_HOST="$(printf '%s' "$ORAS_REF" | cut -d'/' -f1)"

              WORKING_DIR=/workspace
              EXTRACT_DIR="$WORKING_DIR/extracted"

              ASSET_SOURCE="${ASSET_SOURCE:-.}"
              ASSET_TARGET="${ASSET_TARGET:-.}"

              apk update && apk add rsync

              if [ -s "$GITHUB_PAT" ]; then
                echo "[oras] logging in to $REGISTRY_HOST as $GITHUB_USER"
                oras login "$REGISTRY_HOST" -u "$GITHUB_USER" -p "$(cat "$GITHUB_PAT")"
              fi

              echo "[oras] resolving latest tag for $ORAS_REF..."
              LATEST_TAG="$(oras repo tags "$ORAS_REF" 2>/dev/null | sort -V | tail -n1)"
              if [ -z "$LATEST_TAG" ]; then
                echo "[oras] ERROR: no tags found for $ORAS_REF" >&2
                exit 1
              fi

              REF="$ORAS_REF:$LATEST_TAG"
              echo "[oras] pulling $REF..."
              oras pull "$REF"

              echo "[oras] extracting archive into $EXTRACT_DIR"
              mkdir -p "$EXTRACT_DIR"
              tar -xzvf "$WORKING_DIR/assets.tgz" -C "$EXTRACT_DIR"

              SRC="$EXTRACT_DIR/$ASSET_SOURCE"
              DEST="/assets/$ASSET_TARGET"

              echo "[augment] Copying from '$SRC' to '$DEST'"

              # augment image files with large files from OCI
              mkdir -p "$DEST"
              echo "[augment] Copying asset files (add-only)"
              rsync -av --update --chown=${HOST_UID:-1000}:${HOST_GID:-1000} "$SRC"/ "$DEST"/

              # correct permissions
              find "$DEST" -type d -exec chmod 755 {} +
              find "$DEST" -type f -exec chmod 644 {} +
              chown -R ${HOST_UID:-1000}:${HOST_GID:-1000} "$DEST"

              # Debugging output
              pwd && ls -lahR "$DEST"
              COUNT=$(find "$DEST" -type f | wc -l || true)
              echo "[augment] Copied $COUNT files: $COUNT"

              echo "[augment] Finished processing assets"

          volumeMounts:
            - name: assets
              mountPath: /assets
            - name: job-secrets
              mountPath: /etc/secrets
              readOnly: true
      volumes:
        - name: assets
          persistentVolumeClaim:
            claimName: {{ .Values.assets.pvcName | default "multimedia-assets" | quote }}
        - name: job-secrets
          projected:
            sources:
              - secret:
                  name: {{ .Values.assets.secretName | default "legacy-github-token" | quote }}
                  items:
                    - key: GITHUB_TOKEN
                      path: GITHUB_TOKEN
{{- end }}
{{- end -}}
