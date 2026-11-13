{{- define "karazin.name" -}}
{{- printf "%s-%s" .root.Release.Name .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "karazin.migrationName" -}}
{{- printf "%s-migrate-%d" (.Release.Name | trunc 42 | trimSuffix "-") .Release.Revision -}}
{{- end -}}

{{- define "karazin.selector" -}}
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/name: {{ .root.Chart.Name | quote }}
app.kubernetes.io/component: {{ .component | quote }}
{{- end -}}

{{- define "karazin.image" -}}
{{- $repository := .image.repository -}}
{{- if not $repository -}}
{{- $repository = printf "%s%s" (required "Set images.repository or the component image repositories" .root.Values.images.repository) .suffix -}}
{{- end -}}
{{- if .image.digest -}}
{{- printf "%s@%s" $repository .image.digest -}}
{{- else -}}
{{- printf "%s:%s" $repository .image.tag -}}
{{- end -}}
{{- end -}}

{{- define "karazin.password" -}}
valueFrom:
  secretKeyRef:
    name: {{ required "Set postgresql.existingSecret" .Values.postgresql.existingSecret | quote }}
    key: {{ .Values.postgresql.passwordKey | quote }}
{{- end -}}

{{- define "karazin.databaseEnv" -}}
- name: SERVERPOD_DATABASE_HOST
  value: {{ include "karazin.name" (dict "root" . "component" "postgres") | quote }}
- name: SERVERPOD_DATABASE_PORT
  value: {{ .Values.postgresql.port | quote }}
- name: SERVERPOD_DATABASE_NAME
  value: {{ .Values.postgresql.name | quote }}
- name: SERVERPOD_DATABASE_USER
  value: {{ .Values.postgresql.user | quote }}
- name: SERVERPOD_DATABASE_PASSWORD
  {{- include "karazin.password" . | nindent 2 }}
- name: SERVERPOD_DATABASE_REQUIRE_SSL
  value: "false"
{{- end -}}

{{- define "karazin.frontendApiUrl" -}}
{{- if .Values.frontend.apiBaseUrl -}}
{{- .Values.frontend.apiBaseUrl -}}
{{- else if .Values.ingress.enabled -}}
{{- $port := int .Values.ingress.publicPort -}}
{{- $scheme := .Values.ingress.publicScheme -}}
{{- printf "%s://%s" $scheme (required "Set ingress.host" .Values.ingress.host) -}}
{{- if not (or (and (eq $scheme "http") (eq $port 80)) (and (eq $scheme "https") (eq $port 443))) -}}
{{- printf ":%d" $port -}}
{{- end -}}
{{- else -}}
{{- required "Set frontend.apiBaseUrl when ingress is disabled" .Values.frontend.apiBaseUrl -}}
{{- end -}}
{{- end -}}
