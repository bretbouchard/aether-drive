# SPICE to KiCad Workflow - Quick Reference

## 🚀 Start New Project

```bash
cd hardware/templates/spice-to-kicad-workflow
./new-project.sh "My Circuit Name"
```

This creates a complete project structure with templates.

## 📋 Workflow Steps

### 1️⃣ SPICE Simulation
```bash
cd projects/my-circuit-name/spice_simulations
# Edit circuit.sp
ngspice -b circuit.sp
# Update validation_report.md
```

### 2️⃣ KiCad Schematic
```bash
cd projects/my-circuit-name/schematics
kicad
# Create schematic with components from:
# ../../kicad_libraries/symbols/
# ../../kicad_libraries/footprints/
# File → Export → Plot → PDF
```

### 3️⃣ Documentation
```bash
cd projects/my-circuit-name/docs
# Edit README.md, schematic.md, bom.md, wiring_guide.md
```

### 4️⃣ Validation
```bash
cd projects/my-circuit-name
./validate.sh
```

## 📁 Project Structure

```
projects/my-circuit-name/
├── spice_simulations/
│   ├── circuit.sp              # SPICE netlist (template provided)
│   └── validation_report.md   # Results template
├── schematics/
│   └── README.md              # Schematic guide
├── docs/
│   ├── README.md              # Project overview
│   ├── schematic.md           # Circuit description
│   ├── bom.md                 # Component list
│   └── wiring_guide.md        # Assembly instructions
├── images/                     # Screenshots
├── go.sh                      # Quick command reference
└── validate.sh                # Project validation
```

## ✅ Validation Checkpoints

### After SPICE
- [ ] Simulation runs without errors
- [ ] Voltages within specs
- [ ] Currents within ratings
- [ ] Power consumption acceptable
- [ ] Validation report complete

### After KiCad
- [ ] All components placed
- [ ] Wiring complete
- [ ] Power/GND symbols placed
- [ ] Footprints assigned
- [ ] PDF exported

### After Documentation
- [ ] README.md complete
- [ ] Schematic documented
- [ ] BOM generated
- [ ] Wiring guide created

## 🔧 Available Libraries

**KiCad Libraries (already downloaded):**
- Symbols: `hardware/kicad_libraries/symbols/`
- Footprints: `hardware/kicad_libraries/footprints/`

**Total:**
- 3,114 symbol libraries
- 12,312 footprint files
- All common components included

## 📱 Quick Commands

```bash
# See project status
./go.sh

# Validate project
./validate.sh

# Run SPICE
cd spice_simulations && ngspice -b circuit.sp

# Open KiCad
cd schematics && kicad
```

## 🎯 Standard Workflow

1. **New Project** → `./new-project.sh "Name"`
2. **SPICE** → Edit `circuit.sp`, run simulation
3. **KiCad** → Create schematic, export PDF
4. **Document** → Fill in templates
5. **Validate** → `./validate.sh`
6. **Commit** → Git commit with detailed message

## 📋 Example: PB86 Circuit

```bash
# Start new project
./new-project.sh "PB86 8-Button Circuit"
cd projects/pb86-8-button-circuit

# SPICE simulation
cd spice_simulations
# [Edit circuit.sp - already done]
ngspice -b circuit.sp
# ✅ Validated: 15mA LED, 120mA power

# KiCad schematic
cd ../schematics
kicad pb86.kicad_pro
# [Create schematic with components]
# File → Export → Plot → PDF
# ✅ Schematic complete

# Documentation
cd ../docs
# [Fill in templates]
# ✅ Documentation complete

# Validate
cd ..
./validate.sh
# ✅ All checks pass
```

## 🔍 Project Status

Current project (PB86):
- ✅ SPICE validated
- ✅ KiCad libraries downloaded
- ✅ Documentation templates created
- ⏳ KiCad schematic (needs GUI)
- ⏳ PDF export (needs KiCad)

## 💡 Best Practices

1. **Always SPICE first** - Never skip validation
2. **Use templates** - Consistent structure
3. **Document everything** - Every decision, result
4. **Validate at each step** - Don't proceed until validation passes
5. **Commit frequently** - Git history is your friend

## 🆘 Troubleshooting

**SPICE errors:**
- Check syntax in circuit.sp
- Verify models are defined
- Check node connections

**KiCad issues:**
- Use provided libraries (symbols/footprints)
- Check footprint assignments
- Verify all pins connected

**Missing templates:**
- Run `./new-project.sh` again
- Copy from template directory

---

## 🎯 For Any New Circuit

Just say: **"Start new project for [circuit name]"**

Or follow the template:
```bash
cd hardware/templates/spice-to-kicad-workflow
./new-project.sh "Your Circuit Name"
```

Everything is set up and ready to go!

---

Generated with Claude Code via Happy Engineering
White Room Hardware Platform
