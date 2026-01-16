* SPICE Netlist for 8-Button PB86 Circuit
* Created: January 16, 2026
* Purpose: Validate button input + LED output circuits

* ============================================================
* POWER SUPPLY
* ============================================================
VCC 1 0 DC 5.0

* ============================================================
* DECOUPLING CAPACITORS
* ============================================================
C1 VCC 0 100u
C2 VCC 0 100n

* ============================================================
* BUTTON 1
* ============================================================
SW1 NO1_1 IN1_1 VSWITCH
V_BUTTON1 VSWITCH 0 PULSE(0 5 1ms 1ms 100ms 200ms)
R_PULLUP1 IN1_1 VCC 100k
C_IN1 IN1_1 0 10p

* ============================================================
* BUTTON 2
* ============================================================
SW2 NO2_1 IN2_1 VSWITCH2
V_BUTTON2 VSWITCH2 0 PULSE(0 5 10ms 1ms 100ms 200ms)
R_PULLUP2 IN2_1 VCC 100k
C_IN2 IN2_1 0 10p

* ============================================================
* BUTTON 3
* ============================================================
SW3 NO3_1 IN3_1 VSWITCH3
V_BUTTON3 VSWITCH3 0 PULSE(0 5 20ms 1ms 100ms 200ms)
R_PULLUP3 IN3_1 VCC 100k
C_IN3 IN3_1 0 10p

* ============================================================
* BUTTON 4
* ============================================================
SW4 NO4_1 IN4_1 VSWITCH4
V_BUTTON4 VSWITCH4 0 PULSE(0 5 30ms 1ms 100ms 200ms)
R_PULLUP4 IN4_1 VCC 100k
C_IN4 IN4_1 0 10p

* ============================================================
* BUTTON 5
* ============================================================
SW5 NO5_1 IN5_1 VSWITCH5
V_BUTTON5 VSWITCH5 0 PULSE(0 5 40ms 1ms 100ms 200ms)
R_PULLUP5 IN5_1 VCC 100k
C_IN5 IN5_1 0 10p

* ============================================================
* BUTTON 6
* ============================================================
SW6 NO6_1 IN6_1 VSWITCH6
V_BUTTON6 VSWITCH6 0 PULSE(0 5 50ms 1ms 100ms 200ms)
R_PULLUP6 IN6_1 VCC 100k
C_IN6 IN6_1 0 10p

* ============================================================
* BUTTON 7
* ============================================================
SW7 NO7_1 IN7_1 VSWITCH7
V_BUTTON7 VSWITCH7 0 PULSE(0 5 60ms 1ms 100ms 200ms)
R_PULLUP7 IN7_1 VCC 100k
C_IN7 IN7_1 0 10p

* ============================================================
* BUTTON 8
* ============================================================
SW8 NO8_1 IN8_1 VSWITCH8
V_BUTTON8 VSWITCH8 0 PULSE(0 5 70ms 1ms 100ms 200ms)
R_PULLUP8 IN8_1 VCC 100k
C_IN8 IN8_1 0 10p

* ============================================================
* LED CIRCUIT (74HC595 driving LEDs)
* ============================================================
V_LED1 Q1_1 0 PULSE(0 5 0ms 0ms 50ms 100ms)
R_OUT1 Q1_1 LED1_ANODE 50
D1 LED1_ANODE LED1_CATHODE D_LED
R_LIMIT1 LED1_CATHODE 0 150

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

* ============================================================
* SIMULATION COMMANDS
* ============================================================
.TRAN 10u 200m
.PROBE

.END
