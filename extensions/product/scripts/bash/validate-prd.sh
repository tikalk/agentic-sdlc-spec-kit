#!/bin/bash
# PRD Validation Script v1.5.2
# Validates PRD compliance with product extension standards
# Usage: validate-prd.sh [PRD_FILE] [--strict|--warn]
#
# Exit codes:
#   0 = All checks passed
#   1 = Critical failures (in strict mode) or validation errors
#   2 = Warnings only (default warn mode)

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STRICT_MODE=false
WARN_MODE=true
PRD_FILE="${1:-PRD.md}"
WARNINGS=0
ERRORS=0

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --strict)
            STRICT_MODE=true
            WARN_MODE=false
            ;;
        --warn)
            STRICT_MODE=false
            WARN_MODE=true
            ;;
        --help|-h)
            echo "Usage: $0 [PRD_FILE] [--strict|--warn]"
            echo ""
            echo "Validates PRD compliance with product extension v1.5.2 standards"
            echo ""
            echo "Options:"
            echo "  --strict    Exit with error on any issue (default: warn only)"
            echo "  --warn      Show warnings but don't exit with error (default)"
            echo "  --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                          # Validate PRD.md with warnings"
            echo "  $0 my-prd.md --strict       # Strict validation of my-prd.md"
            echo "  $0 .specify/product/sections/ecosystem/overview.md  # Validate section"
            exit 0
            ;;
    esac
done

# Check if file exists
if [[ ! -f "$PRD_FILE" ]]; then
    echo -e "${RED}ERROR: PRD file not found: $PRD_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Validating PRD: $PRD_FILE${NC}"
echo -e "${BLUE}Extension Version: 1.5.2 | Mode: $([ "$STRICT_MODE" == true ] && echo "STRICT" || echo "WARN")${NC}"
echo "================================================"

# Function to report success
pass() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to report warning
warn() {
    if [[ "$WARN_MODE" == true ]]; then
        echo -e "${YELLOW}⚠ WARNING${NC}: $1"
    else
        echo -e "${RED}✗ ERROR${NC}: $1"
    fi
    ((WARNINGS++))
}

# Function to report error
fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((ERRORS++))
}

# ============================================
# CHECK 1: Visual Summary Section at Section 1
# ============================================
echo ""
echo -e "${BLUE}[1/7] Checking Visual Summary placement...${NC}"

# Get the first section header
FIRST_SECTION=$(grep -E '^## [0-9]+\.?\s' "$PRD_FILE" | head -1 || echo "")

if [[ -z "$FIRST_SECTION" ]]; then
    fail "No numbered sections found (## 1. format required)"
else
    # Check if first section is "1. Visual Summary"
    if echo "$FIRST_SECTION" | grep -qiE '^## 1\.\s*Visual Summary'; then
        pass "Section 1 is 'Visual Summary' (numbered correctly)"
    elif echo "$FIRST_SECTION" | grep -qiE '^## 1\.\s*Document Information'; then
        warn "Section 1 is 'Document Information' - should be 'Visual Summary' per v1.5.2"
        echo "  Expected: ## 1. Visual Summary"
        echo "  Found: $FIRST_SECTION"
    elif echo "$FIRST_SECTION" | grep -qiE 'Visual Summary'; then
        warn "Visual Summary found but not as Section 1: $FIRST_SECTION"
    else
        warn "Section 1 is: $FIRST_SECTION"
        warn "Expected Section 1 to be 'Visual Summary' per v1.5.2 template"
    fi
fi

# Check if Visual Summary exists anywhere
if grep -qiE "^## [0-9]*\.?\s*Visual Summary" "$PRD_FILE"; then
    pass "Visual Summary section exists"
    
    # Check if it has diagram links
    VISUAL_SUMMARY_START=$(grep -n "^## [0-9]*\.?\s*Visual Summary" "$PRD_FILE" | head -1 | cut -d: -f1)
    NEXT_SECTION=$(grep -n "^## [0-9]" "$PRD_FILE" | grep -A1 "^$VISUAL_SUMMARY_START:" | tail -1 | cut -d: -f1)
    
    if [[ -n "$NEXT_SECTION" && "$NEXT_SECTION" != "$VISUAL_SUMMARY_START" ]]; then
        VISUAL_SUMMARY_CONTENT=$(sed -n "${VISUAL_SUMMARY_START},${NEXT_SECTION}p" "$PRD_FILE")
        if echo "$VISUAL_SUMMARY_CONTENT" | grep -qE '\[.*\]\(.*visuals.*\)'; then
            pass "Visual Summary contains diagram links"
        else
            warn "Visual Summary missing diagram links to visuals/ directory"
        fi
    fi
else
    fail "No 'Visual Summary' section found - REQUIRED per extension v1.5.2"
fi

# ============================================
# CHECK 2: No ASCII Diagrams in Main Content
# ============================================
echo ""
echo -e "${BLUE}[2/7] Checking for ASCII diagrams...${NC}"

# Box-drawing characters (Unicode range U+2500 to U+257F)
ASCII_LINES=$(grep -n -P '[─━│┃┄┅┆┇┈┉┊┋┌┍┎┏┐┑┒┓└┕┖┗┘┙┚┛├┝┞┟┠┡┢┣┤┥┦┧┨┩┪┫┬┭┮┯┰┱┲┳┴┵┶┷┸┹┺┻┼┽┾┿╀╁╂╃╄╅╆╇╈╉╊╋╌╍╎╏═║╒╓╔╕╖╗╘╙╚╛╜╝╞╟╠╡╢╣╤╥╦╧╨╩╪╫╬╭╮╯╰╱╲╳╴╵╶╷╸╹╺╻╼╽╾╿]' "$PRD_FILE" 2>/dev/null || true)

if [[ -n "$ASCII_LINES" ]]; then
    # Check context - are they in <details> blocks?
    OUTSIDE_DETAILS=false
    
    while IFS= read -r line; do
        LINE_NUM=$(echo "$line" | cut -d: -f1)
        # Simple check: count details tags before this line
        DETAILS_OPEN=$(head -n "$LINE_NUM" "$PRD_FILE" | grep -c "<details>" || true)
        DETAILS_CLOSE=$(head -n "$LINE_NUM" "$PRD_FILE" | grep -c "</details>" || true)
        
        if [[ $DETAILS_OPEN -le $DETAILS_CLOSE ]]; then
            OUTSIDE_DETAILS=true
            break
        fi
    done <<< "$ASCII_LINES"
    
    if [[ "$OUTSIDE_DETAILS" == true ]]; then
        fail "ASCII box-drawing characters found OUTSIDE <details> blocks"
        echo "$ASCII_LINES" | head -3 | while read line; do
            echo "  Line: $line"
        done
        if [[ $(echo "$ASCII_LINES" | wc -l) -gt 3 ]]; then
            echo "  ... and $(( $(echo "$ASCII_LINES" | wc -l) - 3 )) more lines"
        fi
        echo ""
        echo "  ASCII diagrams are ONLY allowed in <details> blocks as fallbacks."
        echo "  Main content MUST use Mermaid (\`\`\`mermaid)"
    else
        pass "ASCII characters found only in <details> blocks (allowed as fallback)"
    fi
else
    pass "No ASCII box-drawing characters found"
fi

# ============================================
# CHECK 3: Mermaid Diagrams Present
# ============================================
echo ""
echo -e "${BLUE}[3/7] Checking Mermaid diagrams...${NC}"

MERMAID_COUNT=$(grep -c "^\s*\`\`\`mermaid" "$PRD_FILE" || true)

if [[ $MERMAID_COUNT -eq 0 ]]; then
    fail "No Mermaid diagrams found - MUST have at least 1"
    echo "  Use: \`\`\`mermaid blocks with flowchart/stateDiagram/etc"
elif [[ $MERMAID_COUNT -lt 2 ]]; then
    warn "Only $MERMAID_COUNT Mermaid diagram(s) - recommend 2+ (hierarchy, deps, flows)"
else
    pass "Found $MERMAID_COUNT Mermaid diagrams"
fi

# Check for deprecated 'graph' keyword
GRAPH_COUNT=$(grep -cE "^\s*graph\s+(TD|TB|LR|BT|RL)" "$PRD_FILE" || true)
if [[ $GRAPH_COUNT -gt 0 ]]; then
    warn "Found $GRAPH_COUNT deprecated 'graph' keyword(s) - use 'flowchart' (Mermaid v10+)"
fi

# ============================================
# CHECK 4: No Unfilled Placeholders
# ============================================
echo ""
echo -e "${BLUE}[4/7] Checking for unfilled placeholders...${NC}"

PLACEHOLDER_PATTERNS=(
    '\[PRODUCT_NAME\]'
    '\[FEATURE_AREA_NAME\]'
    '\[PDR_IDS\]'
    '\[DATE\]'
    '\[PLACEHOLDER\]'
    '\[TODO\]'
    '\[TBD\]'
    '\[Author\]'
    '\[X\.X\]'
)

FOUND_PLACEHOLDERS=0
for pattern in "${PLACEHOLDER_PATTERNS[@]}"; do
    MATCHES=$(grep -n "$pattern" "$PRD_FILE" 2>/dev/null || true)
    if [[ -n "$MATCHES" ]]; then
        while IFS= read -r line; do
            fail "Unfilled placeholder: $line"
        done <<< "$MATCHES"
        FOUND_PLACEHOLDERS=$((FOUND_PLACEHOLDERS + $(echo "$MATCHES" | wc -l)))
    fi
done

if [[ $FOUND_PLACEHOLDERS -eq 0 ]]; then
    pass "No unfilled placeholders found"
fi

# ============================================
# CHECK 5: PDR Traceability
# ============================================
echo ""
echo -e "${BLUE}[5/7] Checking PDR traceability...${NC}"

# Count requirements
REQ_COUNT=$(grep -cE '^\s*\*\*REQ-[0-9]+\*\*' "$PRD_FILE" || true)
# Count PDR references
PDR_REFS=$(grep -cE 'PDR-[0-9]+' "$PRD_FILE" || true)

if [[ $REQ_COUNT -gt 0 ]]; then
    pass "Found $REQ_COUNT requirements (REQ-XXX format)"
    
    # Check if requirements have PDR references
    REQ_LINES=$(grep -n 'REQ-[0-9]' "$PRD_FILE" | cut -d: -f1)
    REQ_WITH_PDR=0
    
    for line_num in $REQ_LINES; do
        # Check next 3 lines for PDR reference
        CONTEXT=$(sed -n "${line_num},$((line_num + 3))p" "$PRD_FILE")
        if echo "$CONTEXT" | grep -qE 'PDR-[0-9]+'; then
            ((REQ_WITH_PDR++))
        fi
    done
    
    if [[ $REQ_WITH_PDR -lt $REQ_COUNT ]]; then
        warn "Only $REQ_WITH_PDR/$REQ_COUNT requirements have PDR traceability"
        echo "  Each requirement MUST reference a source PDR"
    else
        pass "All requirements trace to PDRs"
    fi
else
    warn "No REQ-XXX format requirements found - consider using this format for traceability"
fi

# ============================================
# CHECK 6: Required Sections Present
# ============================================
echo ""
echo -e "${BLUE}[6/7] Checking required sections...${NC}"

REQUIRED_SECTIONS=(
    "1.*Visual Summary"
    "2.*Document Information"
    "Overview"
    "Problem\|The Problem"
    "Goals\|Goals/Objectives"
    "Metrics\|Success Metrics"
    "Personas"
    "Functional Requirements\|Requirements"
    "Non-Functional\|NFRs"
    "Out of Scope\|Out of Scope"
    "Risks\|Risks & Mitigation"
    "Roadmap\|Milestones"
    "PDR Summary\|Product Decision"
)

MISSING_SECTIONS=0
for section_pattern in "${REQUIRED_SECTIONS[@]}"; do
    if ! grep -qiE "^## [0-9]*\.?.*($section_pattern)" "$PRD_FILE"; then
        warn "Missing or misnumbered section matching: $section_pattern"
        ((MISSING_SECTIONS++))
    fi
done

if [[ $MISSING_SECTIONS -eq 0 ]]; then
    pass "All required sections present and numbered"
fi

# ============================================
# CHECK 7: Constitution Alignment Claims
# ============================================
echo ""
echo -e "${BLUE}[7/7] Checking constitution alignment...${NC}"

if grep -qi "Constitution Alignment\|Aligns with Constitution" "$PRD_FILE"; then
    pass "Constitution alignment section found"
    
    # Check if constitution is populated (not just template)
    CONST_FILE=".specify/memory/constitution.md"
    if [[ -f "$CONST_FILE" ]]; then
        if grep -qE '\[PRINCIPLE_[0-9]+_NAME\]|\[PROJECT_NAME\]' "$CONST_FILE" 2>/dev/null; then
            warn "Constitution file contains template placeholders - populate or remove alignment claims"
        else
            pass "Constitution file appears to be populated"
        fi
    else
        warn "Constitution file not found at $CONST_FILE"
    fi
else
    warn "No constitution alignment section found (recommended but not required)"
fi

# ============================================
# SUMMARY
# ============================================
echo ""
echo "================================================"
echo -e "${BLUE}Validation Summary${NC}"
echo "================================================"

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}✓ All checks passed! PRD is compliant with v1.5.2${NC}"
    echo ""
    echo "You may proceed to mark sections as 'completed'"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo "   PRD is usable but has issues that should be addressed"
    echo ""
    
    if [[ "$STRICT_MODE" == true ]]; then
        echo -e "${RED}Exiting with error (strict mode)${NC}"
        echo "   Fix all warnings before marking 'completed'"
        exit 1
    else
        echo "   Run with --strict to enforce no warnings"
        exit 2
    fi
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "PRD is NON-COMPLIANT with v1.5.2 standards"
    echo "Fix all errors before proceeding"
    exit 1
fi
