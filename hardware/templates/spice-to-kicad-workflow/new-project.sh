#!/bin/bash
#
# Create new SPICE to KiCad project
#

set -e

PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: ./new-project.sh \"Project Name\""
    echo ""
    echo "Example: ./new-project.sh \"PB86 8-Button Circuit\""
    exit 1
fi

# Convert project name to directory-safe format
PROJECT_DIR=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
BASE_DIR="$(dirname "$0")/../../projects"
PROJECT_PATH="$BASE_DIR/$PROJECT_DIR"

echo "🚀 Creating new project: $PROJECT_NAME"
echo ""

# Create project structure
echo "📁 Creating project structure..."
mkdir -p "$PROJECT_PATH"/{spice_simulations,schematics,docs,images}

# Create README
cat > "$PROJECT_PATH/README.md" <<EOF
# $PROJECT_NAME

**Created:** $(date +"%Y-%m-%d")
**Status:** In Development

## Overview
[Project description]

## Circuit Design
[High-level description]

## Validation
- **SPICE Simulation:** $(date +"%Y-%m-%d")
- **Status:** Pending

## Files
- \`spice_simulations/\` - SPICE netlists and validation
- \`schematics/\` - KiCad schematic files
- \`docs/\` - Project documentation
- \`images/\` - Screenshots and diagrams

## Next Steps
1. ✅ Project created
2. ⏭️ Create SPICE netlist
3. ⏭️ Run simulation
4. ⏭️ Design KiCad schematic
5. ⏭️ Export PDF

---

Generated with Claude Code via Happy Engineering
EOF

# Create SPICE template
cat > "$PROJECT_PATH/spice_simulations/circuit.sp" <<EOF
* SPICE Netlist for $PROJECT_NAME
* Created: $(date +"%Y-%m-%d")
* Purpose: [Describe circuit purpose]

* ============================================================
* POWER SUPPLY
* ============================================================
VCC 1 0 DC 5.0

* ============================================================
* CIRCUIT DESCRIPTION
* ============================================================
[Add your circuit here]

* ============================================================
* SIMULATION
* ============================================================
.TRAN 10u 10m
.PRINT V(1) V(2)
.END
EOF

# Create validation template
cat > "$PROJECT_PATH/spice_simulations/validation_report.md" <<EOF
# SPICE Validation Report

## Circuit: $PROJECT_NAME
## Date: $(date +"%Y-%m-%d")

## Simulation Results

### Status
⏳ **Pending** - Run SPICE simulation first

### How to Run Simulation
\`\`\`bash
cd spice_simulations
ngspice -b circuit.sp
\`\`\`

### Expected Results
[Document expected voltages, currents, power]

## Validation Checklist
- [ ] Simulation runs without errors
- [ ] Voltage levels within specifications
- [ ] Currents within component ratings
- [ ] Power consumption acceptable
- [ ] Circuit behavior as expected

## Conclusion
[Simulation results summary]

---

Generated: $(date +"%Y-%m-%d")
EOF

# Create schematic README
cat > "$PROJECT_PATH/schematics/README.md" <<EOF
# $PROJECT_NAME Schematic

## Status
⏳ **Not Started** - Complete SPICE validation first

## KiCad Files
- **Project File:** TBD
- **Schematic File:** TBD
- **PDF Export:** TBD

## Component List
| Reference | Component | Value | Package | Quantity |
|-----------|-----------|-------|---------|----------|
| [Add components after design] |

## Design Specifications
- Supply Voltage: TBD
- Power Consumption: TBD
- [Other specs]

## How to Create Schematic

1. **Complete SPICE validation** first
2. **Open KiCad:**
   \`\`\`bash
   kicad
   \`\`\`
3. **Create new project:** \`$PROJECT_DIR.kicad_pro\`
4. **Add components** from:
   - Symbols: \`../../kicad_libraries/symbols/\`
   - Footprints: \`../../kicad_libraries/footprints/\`
5. **Wire components** according to validated circuit
6. **Export to PDF:** File → Export → Plot

## Notes
- Use downloaded KiCad libraries (already have symbols/footprints)
- Follow SPICE-validated design
- Document any deviations from simulation

---

Generated: $(date +"%Y-%m-%d")
EOF

# Create documentation template
cat > "$PROJECT_PATH/docs/schematic.md" <<EOF
# $PROJECT_NAME - Circuit Documentation

## Overview
[Describe the circuit purpose and functionality]

## Circuit Description
[Detailed circuit explanation]

## Design Specifications
- **Supply Voltage:** [Value]
- **Power Consumption:** [Value]
- [Other key specs]

## Component Selection
[Why each component was chosen]

## Validation Results
See: \`../spice_simulations/validation_report.md\`

## Bill of Materials
See: \`bom.md\`

## Assembly Instructions
See: \`wiring_guide.md\`

---

Generated: $(date +"%Y-%m-%d")
EOF

# Create project script
cat > "$PROJECT_PATH/go.sh" <<'PROJECTSCRIPT'
#!/bin/bash
#
# Project workflow script
#

echo "📋 Project: [PROJECT_NAME]"
echo ""
echo "Available commands:"
echo ""
echo "  1. Run SPICE simulation:"
echo "     cd spice_simulations && ngspice -b circuit.sp"
echo ""
echo "  2. Open KiCad schematic:"
echo "     cd schematics && kicad *.kicad_pro"
echo ""
echo "  3. Validate project:"
echo "     ./validate.sh"
echo ""
echo "  4. View documentation:"
echo "     cat README.md"
echo ""
echo "Current status:"
echo "  SPICE: $(cd spice_simulations 2>/dev/null && [ -f validation_report.md ] && echo "✅ Setup complete" || echo "⏳ Not started")"
echo "  Schematic: $(cd schematics 2>/dev/null && ls *.kicad_sch >/dev/null 2>&1 && echo "✅ Created" || echo "⏳ Not started")"
echo ""
PROJECTSCRIPT

# Replace placeholder with actual project name
sed -i '' "s/\[PROJECT_NAME\]/$PROJECT_NAME/g" "$PROJECT_PATH/go.sh"
chmod +x "$PROJECT_PATH/go.sh"

# Create validation script
cat > "$PROJECT_PATH/validate.sh" <<'VALIDATESCRIPT'
#!/bin/bash
#
# Validate project completeness
#

echo "🔍 Validating project..."
echo ""

ERRORS=0

# Check SPICE
echo "Checking SPICE simulation..."
if [ -f "spice_simulations/circuit.sp" ]; then
    echo "  ✅ SPICE netlist exists"
else
    echo "  ❌ Missing SPICE netlist"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "spice_simulations/validation_report.md" ]; then
    echo "  ✅ Validation report exists"
else
    echo "  ⚠️  Run SPICE simulation first"
fi

# Check KiCad
echo ""
echo "Checking KiCad schematic..."
SCHEMATIC_FILES=$(find schematics -name "*.kicad_sch" 2>/dev/null | wc -l)
if [ "$SCHEMATIC_FILES" -gt 0 ]; then
    echo "  ✅ Schematic files found ($SCHEMATIC_FILES)"
else
    echo "  ⏳ No schematic files yet"
fi

PDF_FILES=$(find schematics -name "*.pdf" 2>/dev/null | wc -l)
if [ "$PDF_FILES" -gt 0 ]; then
    echo "  ✅ PDF export exists"
else
    echo "  ⏳ No PDF export yet"
fi

# Check docs
echo ""
echo "Checking documentation..."
REQUIRED_DOCS=("README.md" "schematic.md" "bom.md" "wiring_guide.md")
for doc in "${REQUIRED_DOCS[@]}"; do
    if [ -f "docs/$doc" ]; then
        echo "  ✅ $doc"
    else
        echo "  ⏳ $doc (not created yet)"
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ Project validation passed!"
else
    echo "❌ Found $ERRORS error(s)"
fi

exit $ERRORS
VALIDATESCRIPT

chmod +x "$PROJECT_PATH/validate.sh"

# Success message
echo ""
echo "✅ Project created successfully!"
echo ""
echo "📁 Location: $PROJECT_PATH"
echo ""
echo "📋 Next steps:"
echo "   1. cd $PROJECT_PATH"
echo "   2. ./go.sh          # See available commands"
echo "   3. Edit spice_simulations/circuit.sp"
echo "   4. Run SPICE simulation"
echo "   5. Create KiCad schematic"
echo ""
