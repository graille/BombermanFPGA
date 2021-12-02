# --------------------------------------------------------------------------
# Packages
# --------------------------------------------------------------------------

__add_source_element ${ROOT_DIRECTORY}/parameters.vhd

__add_source_element ${ROOT_DIRECTORY}/packages/pkg_blocks.vhd
__add_source_element ${ROOT_DIRECTORY}/packages/pkg_directions.vhd
__add_source_element ${ROOT_DIRECTORY}/packages/pkg_functions.vhd
__add_source_element ${ROOT_DIRECTORY}/packages/pkg_states.vhd
__add_source_element ${ROOT_DIRECTORY}/packages/pkg_types.vhd

# --------------------------------------------------------------------------
# Module & External libraries
# --------------------------------------------------------------------------

__add_source_element ${ROOT_DIRECTORY}/modules/graphics/vga_controller.vhd

__add_source_element ${ROOT_DIRECTORY}/modules/io/keyboard.vhd

__add_source_element ${ROOT_DIRECTORY}/modules/memory/dual_port_ram_block.vhd
__add_source_element ${ROOT_DIRECTORY}/modules/memory/pixel_ram.vhd

__add_source_element ${ROOT_DIRECTORY}/modules/prng/simple_prng.vhd

__add_source_element ${ROOT_DIRECTORY}/modules/clock/millisecond_counter.vhd

# IP
source ${ROOT_DIRECTORY}/modules/clock/clk_wiz.tcl

# --------------------------------------------------------------------------
# Sources
# --------------------------------------------------------------------------

__add_source_element ${ROOT_DIRECTORY}/game/game_controller.vhd
__add_source_element ${ROOT_DIRECTORY}/game/graphic_controller.vhd
__add_source_element ${ROOT_DIRECTORY}/game/io_controller.vhd
__add_source_element ${ROOT_DIRECTORY}/game/phy_engine.vhd
__add_source_element ${ROOT_DIRECTORY}/game/player_to_grid.vhd

# --------------------------------------------------------------------------
# Generated assets ROMs
# --------------------------------------------------------------------------

__add_source_element ${ROOT_DIRECTORY}/roms/sprite_converter.vhd
__add_source_element ${ROOT_DIRECTORY}/roms/ressources_sprite_rom.vhd
__add_source_element ${ROOT_DIRECTORY}/roms/font_sprite_rom.vhd
__add_source_element ${ROOT_DIRECTORY}/roms/characters_sprite_rom.vhd

# --------------------------------------------------------------------------
# Module - Top module
# --------------------------------------------------------------------------

# Packages
__add_source_element ${ROOT_DIRECTORY}/game_top.vhd

# Constraints
__add_source_element ${ROOT_DIRECTORY}/constraints/n4_ddr.xdc constrs_1
__add_source_element ${ROOT_DIRECTORY}/constraints/n4.xdc constrs_1

set_property target_constrs_file ${ROOT_DIRECTORY}/constraints/n4_ddr.xdc [current_fileset -constrset]
update_compile_order -fileset sources_1

set_property top GAME_TOP [current_fileset]