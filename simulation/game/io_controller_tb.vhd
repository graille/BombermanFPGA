library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity io_controller_tb is
end io_controller_tb;

architecture behavioural of io_controller_tb is
    constant PERIOD : time := 12.5ns;
    signal clk, rst : std_logic := '0';
    
    signal in_command : std_logic_vector(15 downto 0);
    signal out_command : io_signal;
begin
    clk <= not(clk) after PERIOD/2;
    I_IO_CONTROLLER_TB : entity work.io_controller
        generic map (
            FREQUENCY => 8000
        )
        port map (
            CLK => CLK,
            RST => RST,
            in_command => in_command,
            out_command => out_command
        );

    -- RAM simulation
    process
    begin
        wait for 10*PERIOD;
        in_command <= x"001D";
        
        wait for PERIOD;
        in_command <= x"0000";
        
        wait for 5000*PERIOD;
    end process;
end behavioural;
