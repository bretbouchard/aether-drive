#!/bin/bash
#
# Project workflow script
#

echo "📋 Project: Capacitive Touch XY Pad"
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
