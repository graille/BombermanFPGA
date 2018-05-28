library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity io_controller is
    port(
        CLK, RST : in std_logic;

        in_command : in io_signal;
        out_command : out io_signal
    );
end io_controller;

architecture behavioral of io_controller is
    type command_reg_type is array(5 * NB_PLAYERS - 1 downto 0) of io_signal;
begin
    
end behavioral;
