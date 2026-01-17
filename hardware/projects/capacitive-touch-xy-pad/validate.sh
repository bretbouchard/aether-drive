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
