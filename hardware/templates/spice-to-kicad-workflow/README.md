# SPICE to KiCad Workflow Template

## Overview

This template provides a standardized workflow for designing circuits:
1. **SPICE Simulation** - Validate circuit behavior
2. **KiCad Schematic** - Create professional schematic
3. **PCB Layout** - Design physical board
4. **Documentation** - Complete project records

## Quick Start

```bash
# Start new project
cd hardware/templates/spice-to-kicad-workflow
./new-project.sh "My Circuit Name"

# This creates:
# - projects/my-circuit-name/
#   ├── spice_simulations/
#   ├── schematics/
#   ├── docs/
#   └── README.md
```

## Workflow Steps

### Step 1: SPICE Simulation (Validation)

**Create SPICE netlist:**
```bash
cd projects/my-circuit-name/spice_simulations
# Edit circuit.sp
ngspice -b circuit.sp
```

**What to validate:**
- ✅ Circuit behavior (voltages, currents)
- ✅ Power consumption
- ✅ Component stress (within ratings)
- ✅ Signal integrity

**Output:**
- `circuit.sp` - SPICE netlist
- `validation_report.md` - Results

### Step 2: KiCad Schematic

**Create schematic:**
```bash
cd projects/my-circuit-name/schematics
# Open KiCad
kicad my-project.kicad_pro
```

**Use downloaded libraries:**
- Symbols: `hardware/kicad_libraries/symbols/`
- Footprints: `hardware/kicad_libraries/footprints/`

**Export to PDF:**
- File → Export → Plot
- Format: PDF
- Include: Title block, border

### Step 3: Documentation

**Required docs:**
1. `README.md` - Project overview
2. `schematic.md` - Circuit description
3. `validation_report.md` - SPICE results
4. `bom.md` - Bill of materials
5. `wiring_guide.md` - Assembly instructions

## File Structure

```
projects/my-circuit-name/
├── spice_simulations/
│   ├── circuit.sp              # SPICE netlist
│   ├── validation_report.md   # Simulation results
│   └── test_output.log         # Simulation output
├── schematics/
│   ├── my-circuit.kicad_sch   # KiCad schematic
│   ├── my-circuit.kicad_pro   # KiCad project
│   ├── my-circuit.pdf          # Exported PDF
│   └── README.md              # Schematic notes
├── docs/
│   ├── README.md              # Project overview
│   ├── schematic.md           # Circuit description
│   ├── bom.md                 # Component list
│   └── wiring_guide.md        # Assembly instructions
└── images/
    ├── screenshot.png         # Schematic screenshot
    └── pcb_preview.png        # PCB preview (if applicable)
```

## Templates

### SPICE Netlist Template

```spice
* Project: [Project Name]
* Date: [YYYY-MM-DD]
* Purpose: [Circuit description]

* Power Supply
VCC VCC 0 DC 5.0

* Input Circuit
[Your circuit here]

* Models
.MODEL [Component Name] [Parameters]

* Simulation
.TRAN [Step] [Stop_time]
.PRINT [Variables]
.END
```

### Validation Report Template

```markdown
# SPICE Validation Report

## Circuit: [Name]
## Date: [YYYY-MM-DD]

## Simulation Results

### Voltage Analysis
- [Voltage 1]: [Value]
- [Voltage 2]: [Value]

### Current Analysis
- [Current 1]: [Value]
- [Current 2]: [Value]

### Power Consumption
- Total: [Value]

### Component Stress
- [Component]: [Status]

## Conclusion
✅ Circuit validated - proceed to KiCad schematic
```

### Schematic Documentation Template

```markdown
# [Project Name] Schematic

## Overview
[Circuit description]

## Components
| Part | Value | Package | Quantity |
|------|-------|---------|----------|
| [List] |

## Design Specifications
- Supply Voltage: [Value]
- Power Consumption: [Value]
- [Key specs]

## Validation
- SPICE: [Date]
- Results: [Link to report]

## KiCad Files
- Schematic: [File]
- PDF Export: [File]
```

## Checklists

### SPICE Simulation Checklist
- [ ] Netlist syntax valid
- [ ] Simulation runs without errors
- [ ] Voltage levels within specs
- [ ] Currents within ratings
- [ ] Power consumption acceptable
- [ ] No component overstress

### KiCad Schematic Checklist
- [ ] All components placed
- [ ] Wires connected properly
- [ ] Power symbols placed
- [ ] Ground symbols placed
- [ ] No unconnected pins (except NC)
- [ ] Components have footprints
- [ ] Values set correctly
- [ ] Reference designators unique

### Documentation Checklist
- [ ] README.md complete
- [ ] Schematic documented
- [ ] BOM generated
- [ ] Validation report included
- [ ] Wiring guide created

## Commands Reference

```bash
# New project
./new-project.sh "Project Name"

# Run SPICE simulation
cd projects/[project-name]/spice_simulations
ngspice -b circuit.sp

# Open KiCad
cd projects/[project-name]/schematics
kicad project.kicad_pro

# Export schematic to PDF
# In KiCad: File → Export → Plot → PDF

# Validate project
cd projects/[project-name]
./validate-project.sh
```

## Best Practices

1. **Always SPICE first** - Never skip simulation
2. **Document everything** - Every decision, calculation, result
3. **Use standard libraries** - Downloaded KiCad libraries
4. **Version control** - Commit after each major step
5. **Review before proceeding** - Each step must pass validation

## Next Steps After Schematic

1. ✅ SPICE validated
2. ✅ Schematic created
3. ⏭️ **PCB Layout** (next phase)
4. ⏭️ **Prototype build**
5. ⏭️ **Testing**

## Support

- KiCad libraries: `hardware/kicad_libraries/`
- SPICE templates: `spice_simulations/`
- Documentation templates: `docs/`

---

Generated with Claude Code via Happy Engineering
White Room Hardware Platform
