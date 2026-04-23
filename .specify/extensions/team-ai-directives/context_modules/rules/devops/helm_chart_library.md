# Rule: Helm Chart Library Pattern

## Checklist
- Create a Helm library chart (`type: library`) with reusable named templates
- Use `lib.` prefix for all library template names (e.g., `lib.deployment`, `lib.env`, `lib.service`)
- Define helper functions in `templates/_helpers.yaml` for common Kubernetes resource generation
- Application charts depend on chart library via `Chart.yaml` dependencies
- Application charts use `include` to compose resources from library templates
- Never duplicate library logic in application charts - always inherit from library
- Follow "smallest possible values.yaml" philosophy - calculate values in templates
- Document all library template parameters and usage patterns

## Overview

The Helm chart library pattern enables DRY (Don't Repeat Yourself) configuration management by centralizing reusable Kubernetes resource templates in a library chart. Application charts compose services using these library templates, eliminating duplication and ensuring consistency.

**Related Rules:**
- See `helm_packaging.md` for general Helm packaging principles and values design philosophy
- See `secrets_management_dry.md` for DRY secrets management patterns used with chart libraries

## Chart Library Structure

### Library Chart Definition

Create a Helm library chart with `type: library`:

```yaml
# chart-library/Chart.yaml
apiVersion: v2
name: chart-library
description: Reusable Helm chart library with shared templates
type: library
version: 0.1.0
```

**Key Characteristics:**
- **Type**: Must be `library` (not `application`)
- **No Resources**: Library charts don't deploy resources directly
- **Templates Only**: Contains reusable templates in `templates/` directory
- **Versioned**: Use semantic versioning for library releases

### Directory Structure

```
chart-library/
├── Chart.yaml                    # Library chart definition
├── templates/
│   ├── _helpers.yaml             # Helper functions and named templates
│   ├── _deployment.yaml          # Deployment template
│   ├── _service.yaml             # Service template
│   └── _configmap.yaml           # ConfigMap template (if needed)
└── README.md                     # Library documentation
```

## Named Template Pattern

### Template Naming Convention

Use `lib.` prefix for all library templates:

- **Resource Templates**: `lib.deployment.tpl`, `lib.service.tpl`, `lib.configmap.tpl`
- **Helper Functions**: `lib.name`, `lib.fullname`, `lib.labels`, `lib.env`, `lib.image`
- **Composition Helpers**: `lib.merge`, `lib.selectorLabels`, `lib.podlabels`

**Example:**
```yaml
{{- define "lib.deployment.tpl" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "lib.fullname" . }}
  {{- include "lib.labels" . | nindent 2 }}
spec:
  # ... deployment spec
{{- end }}
```

### Helper Function Patterns

#### Common Helpers

**Name Generation:**
```yaml
{{- define "lib.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "lib.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
```

**Label Generation:**
```yaml
{{- define "lib.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lib.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "lib.labels" -}}
labels:
  helm.sh/chart: {{ include "lib.chart" . }}
  {{- include "lib.selectorLabels" . | nindent 2 }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
```

## Core Library Templates

### lib.deployment

Generate Deployment resources from simple values:

```yaml
{{- define "lib.deployment.tpl" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "lib.fullname" . }}
  {{- include "lib.labels" . | nindent 2 }}
spec:
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit | default 1 }}
  {{- include "lib.replicas" . | nindent 2 }}
  selector:
    matchLabels:
      {{- include "lib.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      {{- include "lib.podlabels" . | nindent 6 }}
    spec:
      containers:
        - name: {{ include "lib.fullname" . }}
          {{- include "lib.image" . | nindent 10 }}
          {{- include "lib.env" . | nindent 10 }}
          {{- include "lib.resources" . | nindent 10 }}
{{- end }}
```

**Usage in Application Chart:**
```yaml
{{- include "lib.deployment.tpl" . }}
```

### lib.env

Auto-generate environment variables from simple declarations:

```yaml
{{- define "lib.env" -}}
{{- $env := dict }}
{{- range $key, $value := .Values.secret }}
{{-   $env = merge ( dict $key (dict "valueFrom" (dict "secretKeyRef" (dict "name" ($.Values.secretName | default (include "lib.fullname" $)) "key" (tpl ($value) $))))) $env }}
{{- end }}
{{- if .Values.env }}
{{-   $env = merge (deepCopy .Values.env) $env }}
{{- end }}
{{- with $env }}
env:
{{- range $key, $value := . }}
  - name: {{ $key }}
    {{- tpl (toYaml $value) $ | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
```

**Values Input (Simple):**
```yaml
# values.yaml
secret:
  DATABASE_URL: "database-url-key"
  API_KEY: "api-key-key"
env:
  LOG_LEVEL: "info"
  ENVIRONMENT: "production"
```

**Generated Output (Complex):**
```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: myapp
        key: database-url-key
  - name: API_KEY
    valueFrom:
      secretKeyRef:
        name: myapp
        key: api-key-key
  - name: LOG_LEVEL
    value: "info"
  - name: ENVIRONMENT
    value: "production"
```

### lib.service

Generate Service resources with sensible defaults:

```yaml
{{- define "lib.service.tpl" }}
{{- $serviceType := .Values.service.type | default "ClusterIP" }}
{{- $servicePort := .Values.service.port | default 80 }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "lib.fullname" . }}
  {{- include "lib.labels" . | nindent 2 }}
spec:
  type: {{ $serviceType }}
  ports:
    - port: {{ $servicePort }}
      targetPort: http
      protocol: TCP
  selector:
    {{- include "lib.selectorLabels" . | nindent 4 }}
{{- end }}
```

## Umbrella Chart Composition

### Application Chart Dependencies

Application charts depend on the chart library:

```yaml
# [platform]/Chart.yaml
apiVersion: v2
name: platform
description: Umbrella chart for all services
type: application
version: 0.1.0

dependencies:
  - name: chart-library
    version: "0.1.0"
    repository: "file://../chart-library/"
  
  - name: backoffice
    version: "0.1.0"
    condition: backoffice.enabled
  
  - name: [service-name]
    version: "0.1.0"
    condition: [service-name].enabled
```

### Service Chart Usage

Service charts use library templates via `include`:

```yaml
# [service]/templates/deployment.yaml
{{- include "lib.deployment.tpl" . }}
```

**Values File (Minimal):**
```yaml
# [service]/values.yaml
image:
  repository: [registry]/[service-name]
  tag: "1.0.0"

replicas: 3

service:
  type: ClusterIP
  port: 80

secret:
  DATABASE_URL: "database-url-key"
```

**No Duplication**: Service charts never duplicate library template logic - they only provide values and include library templates.

## Values Philosophy

### Smallest Possible values.yaml

Follow the "smallest possible values.yaml" principle:

**Calculate in Templates:**
- Resource limits from requests
- Full names from chart/release names
- Labels from chart metadata
- Port configurations from defaults

**Only Expose:**
- User-configurable values
- Environment-specific overrides
- Service-specific requirements

**Example:**
```yaml
# values.yaml - minimal user input
image:
  repository: [registry]/[service]
  tag: "1.0.0"

replicas: 3

# Template calculates:
# - resource limits (2x requests)
# - full resource names
# - standard labels
# - health check ports
```

## Template Composition

### Using `include` for Composition

Compose complex resources from library templates:

```yaml
# templates/deployment.yaml
{{- include "lib.deployment.tpl" . }}
```

**With Indentation:**
```yaml
spec:
  template:
    spec:
      {{- include "lib.env" . | nindent 6 }}
      {{- include "lib.volumes" . | nindent 6 }}
```

### Template Parameters

Library templates receive the standard Helm context (`.`) and can access:
- `.Values` - Chart values
- `.Chart` - Chart metadata
- `.Release` - Release information
- `.Template` - Template functions

**No Custom Parameters**: Library templates use the standard Helm context - no need for custom parameter passing.

## Best Practices

### Library Design
- **Single Responsibility**: Each template should have one clear purpose
- **Composable**: Templates should work together via `include`
- **Documented**: Document all template parameters and usage
- **Tested**: Test templates with various value combinations

### Application Chart Design
- **Inherit, Don't Duplicate**: Always use library templates, never copy logic
- **Minimal Values**: Only provide values that can't be calculated
- **Override-Friendly**: Structure values to allow easy overrides
- **Clear Dependencies**: Explicitly declare chart library dependency

### Template Naming
- **Consistent Prefix**: Use `lib.` prefix for all library templates
- **Descriptive Names**: Template names should clearly indicate purpose
- **Resource Suffix**: Use `.tpl` suffix for resource templates (e.g., `lib.deployment.tpl`)

## Anti-Patterns

- **Duplicating Library Logic**: Don't copy library template code into application charts
- **Hardcoding Values**: Don't hardcode values in templates - use `.Values`
- **Complex Templates**: Don't create overly complex templates - break into smaller helpers
- **Missing Documentation**: Don't create templates without documenting parameters
- **Tight Coupling**: Don't create templates that depend on specific value structures
- **No Versioning**: Don't skip versioning for library charts
- **Application-Type Library**: Don't use `type: application` for library charts

## Rationale

The Helm chart library pattern provides:

- **DRY Configuration**: Eliminates duplication across multiple charts
- **Consistency**: Ensures all charts follow the same patterns and conventions
- **Maintainability**: Changes to common patterns only need to be made once
- **Simplicity**: Application charts become simple value files with template includes
- **Scalability**: Easy to add new services by creating minimal value files

The "smallest possible values.yaml" philosophy reduces cognitive load for chart users while maintaining flexibility. Library templates calculate derived values automatically, making charts easier to use and less error-prone.

This pattern is essential for organizations managing multiple Helm charts and aligns with the DRY principle central to platform engineering best practices.

