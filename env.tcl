set _current_file_location [file normalize [info script]]
set ROOT_DIRECTORY [file dirname $_current_file_location]

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

set PROJECT_NAME "bomberman_project"

# NEXYS-4: xc7a100tcsg324-2
# NEXYS-4 DDR: xc7a100tcsg324-2
# NEXYS VIDEO: XC7A200TSBG484-2
set FPGA_PART_NAME "xc7a100tcsg324-2"
set FPGA_FAMILY ""

# Let FPGA_FAMILY empty if you don't know the correct family
set VIVADO_PROJECT_PATH "${ROOT_DIRECTORY}/vivado"
set IP_LOCATION "${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.srcs/sources_1/ip"

