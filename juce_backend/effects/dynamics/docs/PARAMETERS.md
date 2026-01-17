# Dynamics Parameters

This document describes the parameters for the White Room Dynamics plugin.

## Parameters

### Threshold
- **Range**: -60 dB to 0 dB
- **Description**: Signal level at which compression begins
- **Default**: -20 dB

### Ratio
- **Range**: 1:1 to 20:1
- **Description**: Amount of gain reduction applied above threshold
- **Default**: 4:1

### Attack
- **Range**: 0.1 ms to 100 ms
- **Description**: How quickly compression engages
- **Default**: 10 ms

### Release
- **Range**: 10 ms to 1000 ms
- **Description**: How quickly compression releases
- **Default**: 100 ms

### Makeup Gain
- **Range**: 0 dB to 24 dB
- **Description**: Output gain to compensate for compression
- **Default**: 0 dB

### Wet/Dry Mix
- **Range**: 0% to 100%
- **Description**: Balance between compressed and dry signal
- **Default**: 100%

## Metering

- **Gain Reduction**: Shows current amount of compression
- **Input/Output Level**: Signal level meters
