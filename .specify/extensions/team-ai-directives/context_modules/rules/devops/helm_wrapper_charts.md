# Rule: Helm Wrapper Charts and Template Extension

## Checklist
- Use wrapper charts to extend base/upstream charts without modifying their source code
- Create wrapper charts in a separate repository or directory structure from base charts
- Define wrapper chart dependencies in `Chart.yaml` using the `dependencies` section
- Use `values.yaml` in wrapper chart to override and extend base chart values
- Leverage Helm template functions (`tpl`, `include`, `required`) to extend base chart templates
- Use `_helpers.tpl` in wrapper charts to define reusable template functions
- Override specific templates by creating templates with the same name in the wrapper chart
- Document which base chart version the wrapper extends and any breaking changes
- Version wrapper charts independently from base charts using semantic versioning
- Test wrapper charts against multiple base chart versions when possible

## Wrapper Chart Structure
- **Chart.yaml**: Define dependency on base chart with version constraint
- **values.yaml**: Override and extend base chart values with team-specific defaults
- **templates/**: Override specific templates or add new templates that extend base functionality
- **templates/_helpers.tpl**: Define custom template functions for wrapper chart logic
- **README.md**: Document wrapper chart purpose, base chart version, and customization points

## Template Extension Patterns
- Use `{{- include "base-chart.template.name" . }}` to include base chart templates
- Extend base templates by wrapping them: `{{- include "base-chart.deployment" . | indent 2 }}`
- Add additional resources in wrapper templates that complement base chart resources
- Use conditional logic (`if`, `with`) to enable/disable wrapper features via values
- Leverage `tpl` function to process template strings from values: `{{- tpl .Values.customTemplate . }}`
- Create wrapper-specific labels and annotations that don't conflict with base chart labels

## Values Management
- Use `values.yaml` to set team-specific defaults that override base chart defaults
- Structure values hierarchically to match base chart value structure
- Document all custom values in wrapper chart's `values.yaml` with comments
- Use `required` function for critical values that must be provided: `{{ required "app.name is required" .Values.app.name }}`
- Validate values using template conditionals before rendering resources

## Best Practices
- Keep wrapper charts minimal - only override what's necessary
- Preserve base chart functionality unless explicitly extending or replacing
- Test wrapper charts in isolation before integrating with base chart updates
- Use wrapper charts to enforce organizational standards (naming, labels, resource limits)
- Document breaking changes when base chart versions are updated
- Version wrapper charts to track compatibility with base chart versions
- Use CI/CD to validate wrapper charts against base chart changes

## Anti-Patterns
- Modifying base chart source code directly instead of using wrapper charts
- Duplicating entire base chart templates instead of extending them
- Hardcoding values in templates instead of using values.yaml
- Creating wrapper charts that completely replace base chart functionality
- Ignoring base chart version compatibility when updating wrapper charts
- Mixing application-specific values with wrapper chart defaults

## Rationale
Wrapper charts enable teams to customize and extend upstream Helm charts while maintaining the ability to pull in base chart updates. This pattern promotes reusability, reduces maintenance burden, and allows organizations to enforce standards without forking upstream charts. Template extension through wrapper charts provides flexibility while preserving the declarative nature of Helm configurations.

