# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

set IP_NAME "clk_wiz_0"

# ----------------------------------------------------------------------------
# IP configuration
# ----------------------------------------------------------------------------

set IP_PARAMETERS [list \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.USE_PHASE_ALIGNMENT {true} \
    CONFIG.JITTER_SEL {No_Jitter} \
    CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.PRIMARY_PORT {clk_in1} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT3_USED {true} \
    CONFIG.CLK_OUT1_PORT {clk_out1} \
    CONFIG.CLK_OUT2_PORT {clk_out2} \
    CONFIG.CLK_OUT3_PORT {clk_out3} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {70.000} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {40.000} \
    CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {100.000} \
    CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} \
    CONFIG.USE_LOCKED {false} \
    CONFIG.USE_RESET {false} \
]

__add_ip_element \
    clk_wiz \
    xilinx.com \
    ip \
    6.0 \
    ${IP_NAME} \
    ${IP_LOCATION} \
    ${IP_PARAMETERS}