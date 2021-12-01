# --------------------------------------------------------------------------
# Procedures
# --------------------------------------------------------------------------

set DEFAULT_SOURCES_FILESET "sources_1"

proc __add_source_element {_path args} {
    global VIVADO_PROJECT_PATH PROJECT_NAME DEFAULT_SOURCES_FILESET

    if {[llength $args] == 0} {
        set _fileset ${DEFAULT_SOURCES_FILESET}
    } else {
        set _fileset [lindex $args 0]
    }

    puts "Add source ${_path} to fileset ${_fileset}"

    add_files -quiet -fileset ${_fileset} -norecurse ${_path}
    # update_compile_order -fileset ${_fileset}
}

proc __add_ip_element {_ip_name _ip_vendor _ip_library _ip_version _module_name _path _parameters} {
    global VIVADO_PROJECT_PATH PROJECT_NAME

    puts ""
    puts ">> Generate IP ${_module_name} from ${_ip_name} - ${_ip_version}"

    create_ip \
        -name ${_ip_name} \
        -vendor ${_ip_vendor} \
        -library ${_ip_library} \
        -version ${_ip_version} \
        -module_name ${_module_name} \
        -dir ${_path}

    set_property -dict ${_parameters} [get_ips ${_module_name}]

    # Generate IP targets
    generate_target {instantiation_template} [get_files ${_path}/${_module_name}/${_module_name}.xci]
    generate_target all [get_files ${_path}/${_module_name}/${_module_name}.xci]
    config_ip_cache -export [get_ips -all ${_module_name}]

    # Export files and create runs
    export_ip_user_files -of_objects [get_files ${_path}/${_module_name}/${_module_name}.xci] -no_script -sync -force -quiet
    create_ip_run [get_files -of_objects [get_fileset sources_1] ${_path}/${_module_name}/${_module_name}.xci]
    # launch_runs -jobs 12 ${_module_name}_synth_1

    export_simulation \
        -of_objects [get_files ${_path}/${_module_name}/${_module_name}.xci] \
        -directory ${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.ip_user_files/sim_scripts \
        -ip_user_files_dir ${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.ip_user_files \
        -ipstatic_source_dir ${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.ip_user_files/ipstatic \
        -lib_map_path [ list \
            {modelsim=${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.cache/compile_simlib/modelsim} \
            {questa=${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.cache/compile_simlib/questa} \
            {riviera=${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.cache/compile_simlib/riviera} \
            {activehdl=${VIVADO_PROJECT_PATH}/${PROJECT_NAME}.cache/compile_simlib/activehdl} \
        ] \
        -use_ip_compiled_libs -force -quiet
}