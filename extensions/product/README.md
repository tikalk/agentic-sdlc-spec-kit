# Product Extension

Create and manage Product Requirements Documents (PRD) and Product Decision Records (PDR) for systematic product development.

## Overview

The Product extension provides a comprehensive framework for capturing, managing, and evolving product decisions throughout the product lifecycle. It parallels the [Architect extension](./architect/) but focuses on product management rather than technical architecture.

## Key Concepts

### Product Decision Records (PDR)

PDRs document the *why* behind product decisions - similar to how ADRs document architectural decisions. Each PDR captures:
- The context and problem being solved
- The decision that was made
- Consequences (positive, negative, risks)
- Alternatives considered
- Success metrics

### Product Requirements Document (PRD)

The PRD synthesizes all PDRs into a comprehensive product requirements document with 9 required sections:
1. Overview
2. The Problem
3. Goals/Objectives
4. Success Metrics
5. Personas
6. Functional Requirements
7. Non-Functional Requirements
8. Out of Scope
9. Risks & Mitigation

## Commands

### `/product.specify` - Greenfield Product Exploration

Interactive exploration to create Product Decision Records from product ideas.

```bash
/product.specify "Internal developer platform for self-service infrastructure"
```

**Features:**
- Interactive product exploration through guided discussion
- Feature area decomposition for complex products
- Constitution alignment checking
- PDR generation with full rationale

### `/product.init` - Brownfield Discovery

Reverse-engineer PDRs from existing products.

```bash
/product.init "B2B SaaS product"
```

**Features:**
- Scans existing codebase and documentation
- Detects product signals (monetization, target market, etc.)
- Generates "Discovered" PDRs with confidence levels
- Auto-triggers clarification

### `/product.clarify` - Refine PDRs

Validate and refine existing PDRs.

```bash
/product.clarify "Focus on monetization decisions"
```

**Features:**
- Quality checks against PDR standards
- Constitution alignment verification
- Cross-PDR consistency analysis
- Interactive gap resolution

### `/product.implement` - Generate PRD

Synthesize PDRs into a complete Product Requirements Document.

```bash
/product.implement --sections all
```

**Features:**
- Generates all 9 PRD sections
- PDR traceability throughout
- Configurable section coverage
- Template-based output

### `/product.analyze` - Consistency Analysis

Validate PDR-PRD consistency and completeness.

```bash
/product.analyze "pdrs"
```

**Features:**
- Bidirectional drift detection (PDR→PRD, PRD→PDR)
- Quality scoring
- Staleness detection
- Coverage metrics

### `/product.validate` - Plan Validation

Validate feature spec alignment with PRD (READ-ONLY).

```bash
/product.validate "specs/auth/"
```

**Features:**
- Scope alignment checking
- Persona consistency
- Metric alignment
- Traceability verification

## Workflow

### Greenfield Product

```
1. /product.specify "Product idea"
   ↓
2. PDRs created in .specify/drafts/pdr.md
   ↓
3. /product.clarify (refine if needed)
   ↓
4. /product.implement
   ↓
5. PRD.md generated (to project root or {TEAM_DIRECTIVES}/context_modules/ via PR)
   ↓
6. Feature development with /spec.specify
```

### Brownfield Product

```
1. /product.init "Existing product context"
   ↓
2. Discovered PDRs auto-generated
   ↓
3. /product.clarify (auto-triggered)
   ↓
4. /product.implement
   ↓
5. PRD.md generated (to project root or {TEAM_DIRECTIVES}/context_modules/ via PR)
```

## Integration

### With Architect Extension

The Product extension feeds into the Architect extension:

```
PRD → /architect.specify → ADRs → AD.md
```

### With Spec Extension

Triggered via hooks:
- `before_spec`: Ensure PRD exists before feature specs
- `after_spec`: Validate feature spec alignment with PRD

## Configuration

See [config-template.yml](./config-template.yml) for configuration options.

## Templates

- [pdr-template.md](./templates/pdr-template.md) - Product Decision Record format
- [prd-template.md](./templates/prd-template.md) - Product Requirements Document format

## Examples

See [CNE Agent PRD example](../../CNE%20Agent%20(2).md) for a complete PRD example.

## Dependencies

- **Required**: Git (for version tracking)
- **Speckit**: >=0.0.80

## Tags

- product
- prd
- pdr
- requirements
- product-management

---

*Part of Agentic SDLC Spec Kit - Spec-Driven Development for AI Agents*
