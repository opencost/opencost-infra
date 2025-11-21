{{- define "iperf3.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "iperf3.fullname" -}}
  {{- if .Values.fullnameOverride -}}
    {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- $name := default .Chart.Name .Values.nameOverride -}}
    {{- if contains $name .Release.Name -}}
      {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
    {{- else -}}
      {{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "iperf3.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{- define "iperf3.labels" -}}
helm.sh/chart: {{ include "iperf3.chart" . }}
app.kubernetes.io/name: {{ include "iperf3.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: {{ .Values.mode }}
{{- end -}}

{{- define "iperf3.selectorLabels" -}}
app.kubernetes.io/name: {{ include "iperf3.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "iperf3.serviceAccountName" -}}
  {{- if .Values.serviceAccount.create -}}
    {{- default (include "iperf3.fullname" .) .Values.serviceAccount.name -}}
  {{- else -}}
    {{- default "default" .Values.serviceAccount.name -}}
  {{- end -}}
{{- end -}}

{{- define "iperf3.validateValues" -}}
  {{- if not (has .Values.mode (list "server" "client")) }}
    {{- fail "mode must be either \"server\" or \"client\"" -}}
  {{- end -}}
  {{- if and (eq .Values.mode "client") (not .Values.client.targetHost) }}
    {{- fail "client.targetHost must be provided when mode is set to client" -}}
  {{- end -}}
{{- end -}}

{{- define "iperf3.clientCommand" -}}
iperf3 -c {{ quote .Values.client.targetHost }} -p {{ .Values.client.targetPort }}{{ if gt (int .Values.client.parallelStreams) 1 }} -P {{ .Values.client.parallelStreams }}{{ end }}{{ if .Values.client.udp }} -u{{ end }}{{ if .Values.client.reverse }} -R{{ end }}{{ if gt (int .Values.client.durationSeconds) 0 }} -t {{ .Values.client.durationSeconds }}{{ end }}{{ if gt (int .Values.client.omitSeconds) 0 }} -O {{ .Values.client.omitSeconds }}{{ end }}{{ if .Values.client.json }} -J{{ end }}{{ if .Values.client.bandwidth }} -b {{ .Values.client.bandwidth }}{{ end }}{{- range $arg := .Values.client.extraArgs }} {{ $arg | quote }}{{- end }}
{{- end -}}
