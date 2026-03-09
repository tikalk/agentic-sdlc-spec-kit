# Changelog

All notable changes to the Product extension will be documented in this file.

## [1.0.0] - 2026-03-09

### Added

- Initial release of Product extension

#### Commands

- `adlc.product.specify` - Interactive PRD exploration for greenfield products
- `adlc.product.init` - Brownfield discovery from existing products
- `adlc.product.clarify` - Refine and validate PDRs
- `adlc.product.implement` - Generate PRD from PDRs
- `adlc.product.analyze` - Validate PDR-PRD consistency
- `adlc.product.validate` - Validate feature spec alignment with PRD

#### Templates

- `templates/pdr-template.md` - Product Decision Record template
- `templates/prd-template.md` - Product Requirements Document template (9 sections)

#### Configuration

- `config-template.yml` - Extension configuration

#### Hooks

- `before_spec` - Trigger `/product.specify` before feature specification
- `after_spec` - Trigger `/product.validate` after feature specification

#### Features

- Two-level product system (Product + Feature)
- Feature area decomposition for complex products
- PDR categories: Problem, Persona, Scope, Metric, Prioritization, Business Model, Feature, NFR
- Constitution integration for vision/strategy constraints
- PDR traceability throughout PRD
- Read-only validation commands

---

## Upgrade Notes

### From 0.x

This is the initial release. No upgrade path needed.

## Future Considerations

- Template customization per industry (SaaS, E-commerce, etc.)
- Integration with product management tools (Jira, Productboard)
- Export to common formats (Markdown, Confluence, HTML)
- PDR review workflow automation
