# Helm Template Helpers

**Rule Overview**: Helm template helper functions for consistent naming, label generation, and reusable template logic.

**Rationale**: Reduces template duplication, ensures consistency across charts, provides common utility functions for complex templates.

## Core Patterns

### Naming Convention Functions

**Rule**: Use `_helpers.tpl` for standard template functions: name, fullname, chart, labels, selectorLabels

**Rationale**: Helm conventions, Kubernetes naming constraints, label selectors for services

**Implementation**:
```yaml
# templates/_helpers.tpl
{{/*
Expand the name of the chart.
*/}}
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this.
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "chart.name" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chart.labels" -}}
helm.sh/chart: {{ include "chart.chart" . }}
{{ include "chart.selectorLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

**Reference**: @rule:devops/helm_template_helpers.md

### Helper Function Organization

**Rule**: Group related helper functions logically (naming, labels, URLs, images)

**Rationale**: Maintainability, discoverability, reusability

**Implementation**:
```yaml
# templates/_helpers.tpl
# Naming functions
{{- define "chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "chart.name" .) }}
{{- end }}

{{- define "chart.labels" -}}
{{- include "chart.labels" . }}
{{- end }}

# Label functions
{{- define "chart.selectorLabels" -}}
{{- include "chart.selectorLabels" . }}
{{- end }}

{{- define "chart.standardLabels" -}}
{{ include "chart.selectorLabels" . }}
{{ include "chart.commonLabels" . }}
{{- end }}

{{- define "chart.commonAnnotations" -}}
{{- include "chart.commonAnnotations" . }}
{{- end }}
```

**Reference**: @rule:devops/helm_template_helpers.md

---

## Template Patterns

### Variable Interpolation

**Rule**: Use `.Values` for value interpolation with proper defaults

**Rationale**: Flexibility, configuration consistency, error handling

**Implementation**:
```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "chart.fullname" . }}
  labels:
    {{- include "chart.labels" . }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  template:
    metadata:
      labels:
        {{- include "chart.selectorLabels" . }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          env:
            - name: LOG_LEVEL
              value: "{{ .Values.logLevel | default "INFO" }}"
```

**Reference**: @example:devops/helm_wrapper_chart.md

### Conditional Logic

**Rule**: Use `if`, `else`, and `with` for template conditional logic

**Rationale**: Dynamic configuration, feature toggles, environment-specific logic

**Implementation**:
```yaml
# templates/service.yaml
{{- if .Values.ingress.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "chart.fullname" . }}
spec:
  type: {{ .Values.ingress.type | default "ClusterIP" }}
  ports:
    - port: {{ .Values.service.port | default 80 }}
{{- end }}
```

**Reference**: @example:devops/helm_wrapper_chart.md

### Image and Registry Configuration

**Rule**: Use helper functions for image repository and tag construction

**Rationale**: Consistent image references, version management, registry switching

**Implementation**:
```yaml
# templates/_helpers.tpl
{{- define "image.repository" -}}
{{- if .Values.image.repository }}
{{- .Values.image.repository }}
{{- else }}
{{- printf "%s/%s" .Values.global.imageRepository .Chart.Name }}
{{- end }}

{{- define "image.tag" -}}
{{- if .Values.image.tag }}
{{- .Values.image.tag }}
{{- else }}
{{- printf "v%s" .Chart.AppVersion }}
{{- end }}

{{- define "image.full" -}}
{{ include "image.repository" . }}:{{ include "image.tag" . }}
{{- end }}
```

**Reference**: @example:devops/helm_wrapper_chart.md

---

## Best Practices

### Template Documentation

**Rule**: Include helper function documentation in `_helpers.tpl` for reference

**Rationale**: Self-documenting, team onboarding, discoverability

**Implementation**:
```yaml
# templates/_helpers.tpl
{{/*
Helper function: chart.fullname
Generates a fully qualified app name with proper truncation.

Arguments:
  - .Values.fullnameOverride: Override for full name
  - .Release.Name: Chart release name
  - .Chart.Name: Chart name

Example usage in template:
  metadata:
    name: {{ include "chart.fullname" . }}
*/}}
```

### Error Handling in Templates

**Rule**: Use `required` and `default` function calls for safe value access

**Rationale**: Prevent template rendering errors, provide fallbacks, improve user experience

**Implementation**:
```yaml
# templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "chart.fullname" . }}
data:
  DATABASE_URL: {{ .Values.database.url | required "Database URL is required" }}
  CACHE_SIZE: {{ .Values.cache.size | default "256" }}
```

**Reference**: @example:devops/helm_wrapper_chart.md

---

## Contributing to Team Knowledge Base

### Proposed New Rules
1. **Helper Function Standardization** - Consistent naming conventions and documentation
2. **Variable Interpolation Patterns** - Safe access and defaults
3. **Conditional Logic Best Practices** - Template control flow

### Proposed New Examples
1. **Complete Helpers Template** - Full _helpers.tpl with documentation
2. **Helper Function Examples** - Common patterns for name, labels, and images
3. **Variable Interpolation Examples** - Safe access and defaults

When contributing these back to the repository, follow the guidelines in @CONTRIBUTING.md and use the /levelup process for formalizing new patterns.

---

## Tool Context

- **helm**: Helm package manager and template engine
- **template-engine**: Jinja2 for Kubernetes templates
- **go-template**: Go templates used in Helm

**Rule References**:
- **Wrapper Charts**: @rule:devops/helm_wrapper_charts.md
- **Naming Functions**: @rule:devops/helm_template_helpers.md

**Example References**:
- **Helpers Template**: @example:devops/helm_helpers_template.md
- **Chart Templates**: @example:devops/helm_wrapper_chart.md
