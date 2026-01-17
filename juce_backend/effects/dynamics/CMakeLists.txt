cmake_minimum_required(VERSION 3.15)
project(WhiteRoomDynamics VERSION 1.0.0)

# JUCE setup
set(JUCE_DIR ../juce_backend/core/JUCE)
add_subdirectory(${JUCE_DIR} JUCE)

# Plugin formats
set(JUCE_FORMATS VST3 AU CLAP LV2 Standalone CACHE STRING "Plugin formats to build")

# DSP sources
set(DSP_SOURCES
    src/dsp/AirwindowsInventory.cpp
    src/dsp/Density.cpp
    src/dsp/DynamicAlgorithmSmartControlAdapter.cpp
    src/dsp/DynamicAlgorithmSystem.cpp
    src/dsp/DynamicsEffectsChain.cpp
)

# Create plugin
add_audio_plugin(WhiteRoomDynamics
    SOURCES ${DSP_SOURCES}
    FORMATS ${JUCE_FORMATS}
)

# Installation
install(TARGETS WhiteRoomDynamics
    RUNTIME DESTINATION /Applications
    LIBRARY DESTINATION ~/Library/Audio/Plug-Ins/VST3
)
