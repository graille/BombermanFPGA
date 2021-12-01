# This TCL script generate the Vivado project for JESD204 example project
# It has been tested with the following Vivado version:
#   - 2019.2
# 
# Instructions:
#   1. Update the "env.tcl" file with the informations of your system and FPGA
#   2. Run the TCL script inside Vivado TCL command line

set _current_file_location [file normalize [info script]]
set CURRENT_DIRECTORY [file dirname $_current_file_location]

source ${CURRENT_DIRECTORY}/../env.tcl
source ${CURRENT_DIRECTORY}/commands.tcl

# --------------------------------------------------------------------------
# Project management
# --------------------------------------------------------------------------

# Create project
create_project ${PROJECT_NAME} ${VIVADO_PROJECT_PATH} -part ${FPGA_PART_NAME} -force
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

set_param general.maxThreads 8

file mkdir ${IP_LOCATION}

# --------------------------------------------------------------------------
# Add sources
# --------------------------------------------------------------------------

source ${CURRENT_DIRECTORY}/sources.tcl
puts "Sources added"

puts "Project created. Starting Vivado..."
start_gui
