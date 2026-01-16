# SPICE Simulation Guide - 8-Button PB86 Circuit Validation

## Overview

**Professional workflow**: Simulate first, design PCB later.

SPICE (Simulation Program with Integrated Circuit Emphasis) lets us:
- ✅ **Validate circuit design** before building
- ✅ **Test electrical behavior** (voltage, current, power)
- ✅ **Verify LED current limiting** (prevent burnout)
- ✅ **Check switch debouncing** (digital inputs)
- ✅ **Calculate power consumption**
- ✅ **Debug issues** without soldering

---

## SPICE Software Options

### **LTspice** (Recommended, Free)
- **Download**: https://www.analog.com/en/design-center/design-tools-and-calculators/ltspice-simulator.html
- **Platform**: Windows, Mac, Linux
- **Pros**: Industry standard, huge component library
- **Cons**: Steeper learning curve

### **Ngspice** (Free, Open Source)
- **Download**: http://ngspice.sourceforge.io/
- **Platform**: Mac, Linux, Windows (via WSL)
- **Pros**: Open source, command-line driven
- **Cons**: No GUI schematic editor

### **Micro-Cap** (Free, Student Version)
- **Download**: https://www.spectrum-soft.com/
- **Platform**: Windows only
- **Pros**: Easy to use, good schematic editor
- **Cons**: Windows-only

---

## Circuit Models for SPICE

### What We're Simulating

**3 Parts of the Circuit**:

1. **Button Input Circuit** (MCP23017 + PB86 switches)
   - Switch debouncing
   - Pull-up resistor behavior
   - Input voltage levels

2. **LED Driver Circuit** (74HC595 + LEDs)
   - Current limiting resistors
   - LED forward voltage drop
   - Power consumption

3. **Power Supply** (5V regulation)
   - Current draw
   - Voltage stability
   - Decoupling capacitors

---

## SPICE Netlist Creation

I'll create a **SPICE netlist** that describes your circuit in text format. This file can be:
- Opened in LTspice
- Simulated to validate behavior
- Modified to test "what if" scenarios

---

## Complete SPICE Netlist (8-Button Circuit)

### File: `pb86_8button_circuit.sp`

```spice
* SPICE Netlist for 8-Button PB86 Circuit
* Created: January 16, 2026
* Purpose: Validate button input + LED output circuits

* ============================================================
* POWER SUPPLY
* ============================================================
VCC 1 0 DC 5.0
* VCC is +5V rail
* Node 0 is ground

* ============================================================
* DECOUPLING CAPACITORS
* ============================================================
C1 VCC 0 100u
* Bulk capacitance for power supply

C2 VCC 0 100n
* High-frequency decoupling (close to ICs)

* ============================================================
* BUTTON 1 (All 8 buttons identical)
* ============================================================
* Switch model (PB86 button)
SW1 NO1_1 IN1_1 VSWITCH
* Normally open switch, controlled by VSWITCH
* When VSWITCH = 5V (pressed): IN1_1 connects to NO1_1
* When VSWITCH = 0V (released): IN1_1 floating

* Voltage source to simulate button press
V_BUTTON1 VSWITCH 0 PULSE(0 5 1ms 1ms 100ms 200ms)
* Pulse from 0V to 5V (simulates button press)
* Press at 1ms, release at 101ms

* Pull-up resistor (MCP23017 internal)
R_PULLUP1 IN1_1 VCC 100k
* 100kΩ pull-up to +5V

* Input pin capacitance (MCP23017 GPB pin)
C_IN1 IN1_1 0 10p
* 10pF input capacitance

* ============================================================
* BUTTON 2-8 (Same as Button 1)
* ============================================================
SW2 NO2_1 IN2_1 VSWITCH2
V_BUTTON2 VSWITCH2 0 PULSE(0 5 10ms 1ms 100ms 200ms)
R_PULLUP2 IN2_1 VCC 100k
C_IN2 IN2_1 0 10p

SW3 NO3_1 IN3_1 VSWITCH3
V_BUTTON3 VSWITCH3 0 PULSE(0 5 20ms 1ms 100ms 200ms)
R_PULLUP3 IN3_1 VCC 100k
C_IN3 IN3_1 0 10p

SW4 NO4_1 IN4_1 VSWITCH4
V_BUTTON4 VSWITCH4 0 PULSE(0 5 30ms 1ms 100ms 200ms)
R_PULLUP4 IN4_1 VCC 100k
C_IN4 IN4_1 0 10p

SW5 NO5_1 IN5_1 VSWITCH5
V_BUTTON5 VSWITCH5 0 PULSE(0 5 40ms 1ms 100ms 200ms)
R_PULLUP5 IN5_1 VCC 100k
C_IN5 IN5_1 0 10p

SW6 NO6_1 IN6_1 VSWITCH6
V_BUTTON6 VSWITCH6 0 PULSE(0 5 50ms 1ms 100ms 200ms)
R_PULLUP6 IN6_1 VCC 100k
C_IN6 IN6_1 0 10p

SW7 NO7_1 IN7_1 VSWITCH7
V_BUTTON7 VSWITCH7 0 PULSE(0 5 60ms 1ms 100ms 200ms)
R_PULLUP7 IN7_1 VCC 100k
C_IN7 IN7_1 0 10p

SW8 NO8_1 IN8_1 VSWITCH8
V_BUTTON8 VSWITCH8 0 PULSE(0 5 70ms 1ms 100ms 200ms)
R_PULLUP8 IN8_1 VCC 100k
C_IN8 IN8_1 0 10p

* ============================================================
* LED CIRCUIT (74HC595 driving LEDs)
* ============================================================
* 74HC595 output modeled as voltage source with resistance
V_LED1 Q1_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
* Simulate LED turning ON/OFF
* 0-50ms: OFF, 50-100ms: ON

R_OUT1 Q1_1 LED1_ANODE 50
* Output resistance of 74HC595 (~50Ω)

* LED model (Red LED, 2.0V forward voltage)
D1 LED1_ANODE LED1_CATHODE D_LED
* LED diode model

* Current limiting resistor
R_LIMIT1 LED1_CATHODE 0 150
* 150Ω resistor

* ============================================================
* LED 2-8 (Same as LED 1)
* ============================================================
V_LED2 Q2_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT2 Q2_1 LED2_ANODE 50
D2 LED2_ANODE LED2_CATHODE D_LED
R_LIMIT2 LED2_CATHODE 0 150

V_LED3 Q3_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT3 Q3_1 LED3_ANODE 50
D3 LED3_ANODE LED3_CATHODE D_LED
R_LIMIT3 LED3_CATHODE 0 150

V_LED4 Q4_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT4 Q4_1 LED4_ANODE 50
D4 LED4_ANODE LED4_CATHODE D_LED
R_LIMIT4 LED4_CATHODE 0 150

V_LED5 Q5_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT5 Q5_1 LED5_ANODE 50
D5 LED5_ANODE LED5_CATHODE D_LED
R_LIMIT5 LED5_CATHODE 0 150

V_LED6 Q6_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT6 Q6_1 LED6_ANODE 50
D6 LED6_ANODE LED6_CATHODE D_LED
R_LIMIT6 LED6_CATHODE 0 150

V_LED7 Q7_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT7 Q7_1 LED7_ANODE 50
D7 LED7_ANODE LED7_CATHODE D_LED
R_LIMIT7 LED7_CATHODE 0 150

V_LED8 Q8_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT8 Q8_1 LED8_ANODE 50
D8 LED8_ANODE LED8_CATHODE D_LED
R_LIMIT8 LED8_CATHODE 0 150

* ============================================================
* LED DIODE MODEL
* ============================================================
.MODEL D_LED D(Is=1e-10 Rs=1 N=1.8 Vf=2.0)
* LED model parameters:
* Is = Saturation current
* Rs = Series resistance
* N = Emission coefficient
* Vf = Forward voltage (2.0V for red LED)

* ============================================================
* SIMULATION COMMANDS
* ============================================================
.TRAN 10u 200m
* Transient analysis: 10μs steps, 200ms duration
* Simulates button presses and LED responses

.PROBE
* Save all node voltages for plotting

.END
```

---

## How to Use This Netlist

### Step 1: Save the Netlist

1. Copy the netlist above
2. Save as `pb86_8button_circuit.sp` (plain text file)
3. Put it in a folder (e.g., `spice_simulations/`)

### Step 2: Open in LTspice

**Mac/Linux**:
```bash
# Install LTspice first
brew install --cask ltspice

# Open netlist
open -a LTspice pb86_8button_circuit.sp
```

**Windows**:
1. Open LTspice
2. File → Open
3. Select `pb86_8button_circuit.sp`

### Step 3: Run Simulation

1. Click **Run** (green play button) or press **F2**
2. View waveforms in plot window
3. Click nodes to see voltages

### Step 4: Analyze Results

**What to Check**:
1. ✅ **Button input voltage**: Should go 5V → 0V when pressed
2. ✅ **LED current**: Should be ~20mA when ON
3. ✅ **Power consumption**: Total current < 200mA
4. ✅ **Debouncing**: No bouncing on button press
5. ✅ **LED voltage**: Forward voltage ~2.0V (red LED)

---

## Expected Simulation Results

### Button Input (IN1_1 Node)

```
Voltage (V)
  5 ┤         ┌─────────┐
    │         │         │
  0 ┤─────────┘         └─────────
    └───────────────────────────→ Time
    0ms      1ms      101ms
              Press    Release
```

**What to check**:
- Clean 5V → 0V transition (no bouncing)
- Fast rise/fall times (<1μs)
- No overshoot or ringing

### LED Current (Through R_LIMIT1)

```
Current (mA)
 20┤     ┌─────────────┐
    │     │             │
  0 ┤─────┘             └─────────
    └────────────────────────────→ Time
    0ms  50ms      100ms
         ON        OFF
```

**What to check**:
- Current ~20mA when LED ON
- Current 0mA when LED OFF
- No current spikes (>25mA)

### Power Consumption (Total Current from VCC)

```
Current (mA)
160┤     ┌─────────────┐
    │     │             │
  0 ┤─────┘             └─────────
    └────────────────────────────→ Time
    0ms  50ms      100ms
```

**What to check**:
- All LEDs ON: ~160mA (8 × 20mA)
- All LEDs OFF: ~0mA
- Average: <100mA (typical usage)

---

## Common Issues & Fixes

### Issue 1: LED Current Too High (>25mA)

**Symptom**: LED current exceeds 25mA

**Fix**: Increase current limiting resistor
```spice
* Change from 150Ω to 220Ω
R_LIMIT1 LED1_CATHODE 0 220
```

**Check**: Recalculate current should be ~15mA

### Issue 2: Button Input Bouncing

**Symptom**: Voltage bounces between 5V and 0V

**Fix**: Add debounce capacitor
```spice
* Add 10nF capacitor
C_DEBOUNCE1 IN1_1 0 10n
```

### Issue 3: Voltage Drop on VCC

**Symptom**: VCC drops below 4.5V when all LEDs ON

**Fix**: Increase bulk capacitance
```spice
* Change from 100μF to 470μF
C1 VCC 0 470u
```

---

## Validation Checklist

After running simulation, verify:

- [ ] **Button press detection**: 5V → 0V transition
- [ ] **LED current**: 15-20mA (safe range)
- [ ] **LED forward voltage**: ~2.0V (red LED)
- [ ] **Power consumption**: <200mA total
- [ ] **No bouncing**: Clean digital transitions
- [ ] **Voltage stability**: VCC stays >4.5V
- [ ] **Rise time**: <1μs (fast enough for digital logic)
- [ ] **Fall time**: <1μs (fast enough for digital logic)

---

## Next Steps After Validation

### ✅ If Simulation Passes

1. **Create KiCad schematic**
2. **Design PCB layout**
3. **Order prototype boards**
4. **Assemble and test**

### ❌ If Simulation Fails

1. **Modify netlist** (adjust values)
2. **Re-run simulation**
3. **Iterate until passing**
4. **Then proceed to KiCad**

---

## Alternative: Simplified Simulation

If the full netlist is too complex, start with this **minimal version**:

### Simple LED Test (Single Button)

```spice
* Minimal LED test circuit
VCC 1 0 DC 5.0

* LED circuit
V_LED Q1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT Q1 LED_ANODE 50
D1 LED_ANODE LED_CATHODE D_LED
R_LIMIT LED_CATHODE 0 150

* LED model
.MODEL D_LED D(Is=1e-10 Rs=1 N=1.8 Vf=2.0)

* Simulation
.TRAN 10u 100m
.PROBE
.END
```

**Tests**: Single LED current and voltage

---

## SPICE Resources

### Tutorials
- **LTspice Tutorial**: https://www.analog.com/en/education/education-and-tools/tutorials/ltspice.html
- **SPICE Tutorial**: https://www.allaboutcircuits.com/textbook/spice/

### Component Libraries
- **LTspice Library**: Built-in (huge)
- **YAGP (Yet Another SPICE Package)**: https://yagp.de/

### Help
- **LTspice Forum**: https://groups.io/g/LTspice
- **EEVblog Forum**: https://www.eevblog.com/forum/

---

## Summary

✅ **SPICE simulation validates circuit before building**
✅ **Catches issues early** (no wasted components)
✅ **Optimizes values** (resistors, capacitors)
✅ **Calculates power consumption** accurately
✅ **Professional workflow** (industry standard)

**Workflow**:
1. Run SPICE simulation (this netlist)
2. Validate results (checklist above)
3. Fix any issues
4. Create KiCad schematic
5. Design PCB
6. Build and test

Would you like me to:
1. Create the SPICE netlist file for you?
2. Simplify the netlist (test just LED or button first)?
3. Create a KiCad schematic after SPICE validation?
