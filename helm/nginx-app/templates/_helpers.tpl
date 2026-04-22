{{/*
Fullname
*/}}
{{- define "nginx-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride }}
{{- else if .Values.nameOverride }}
{{- .Values.nameOverride }}
{{- else }}
{{- .Release.Name }}
{{- end }}
{{- end }}

{{/*
Chart labels
*/}}
{{- define "nginx-app.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{ include "nginx-app.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nginx-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nginx-app.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
