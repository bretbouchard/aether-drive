* ============================================================
* Capacitive Touch XY Pad - Simplified SPICE Simulation
* White Room Hardware Platform
* ============================================================
* Simulates mutual capacitance touch sensing
* Models single intersection with and without finger touch
* ============================================================

* ============================================================
* SIMULATION 1: No Touch (Baseline)
* ============================================================
* X electrode (transmitter) - AC source at 100kHz
V_X1 X1_NO_TOUCH 0 SIN(0 3.3 100k) AC 3.3

* Y electrode (receiver) with pullup
R_Y1 Y1_NO_TOUCH 0 1MEG

* Mutual capacitance (no touch)
C_MUTUAL1 X1_NO_TOUCH Y1_NO_TOUCH 50pF

* ============================================================
* SIMULATION 2: Light Touch (Pressure = 0.3)
* ============================================================
* X electrode
V_X2 X2_LIGHT 0 SIN(0 3.3 100k) AC 3.3

* Y electrode with pullup
R_Y2 Y2_LIGHT 0 1MEG

* Mutual capacitance increases slightly
C_MUTUAL2 X2_LIGHT Y2_LIGHT 65pF

* Finger adds capacitance to ground
C_FINGER1 Y2_LIGHT 0 15pF

* ============================================================
* SIMULATION 3: Medium Touch (Pressure = 0.6)
* ============================================================
* X electrode
V_X3 X3_MEDIUM 0 SIN(0 3.3 100k) AC 3.3

* Y electrode with pullup
R_Y3 Y3_MEDIUM 0 1MEG

* Mutual capacitance increases more
C_MUTUAL3 X3_MEDIUM Y3_MEDIUM 80pF

* Finger adds more capacitance to ground
C_FINGER2 Y3_MEDIUM 0 25pF

* ============================================================
* SIMULATION 4: Hard Touch (Pressure = 1.0)
* ============================================================
* X electrode
V_X4 X4_HARD 0 SIN(0 3.3 100k) AC 3.3

* Y electrode with pullup
R_Y4 Y4_HARD 0 1MEG

* Mutual capacitance increases maximum
C_MUTUAL4 X4_HARD Y4_HARD 100pF

* Finger adds maximum capacitance to ground
C_FINGER3 Y4_HARD 0 40pF

* ============================================================
* ANALYSIS
* ============================================================
* AC analysis at 100kHz (carrier frequency)
.AC DEC 10 10k 1Meg

* Transient analysis (show 10 cycles)
.TRAN 0.1u 100u

* ============================================================
* MEASUREMENTS
* ============================================================
* Measure peak voltage at each Y electrode
.MEASURE AC VY_NO_TOUCH MAX V(Y1_NO_TOUCH)
.MEASURE AC VY_LIGHT MAX V(Y2_LIGHT)
.MEASURE AC VY_MEDIUM MAX V(Y3_MEDIUM)
.MEASURE AC VY_HARD MAX V(Y4_HARD)

* ============================================================
* PRINT OUTPUTS
* ============================================================
.PRINT AC V(Y1_NO_TOUCH) V(Y2_LIGHT) V(Y3_MEDIUM) V(Y4_HARD)
.PRINT TRAN V(Y1_NO_TOUCH) V(Y2_LIGHT) V(Y3_MEDIUM) V(Y4_HARD)

.END
