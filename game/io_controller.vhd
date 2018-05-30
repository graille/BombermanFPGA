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
        in_new_command : in std_logic := '0';
        
        in_requested_command : in integer range 0 to NB_CONTROLS - 1;
        in_requested_player : in integer range 0 to NB_PLAYERS - 1;
        out_control_status : out std_logic;
        
        out_do_read : out std_logic := '0'
    );
end io_controller;

architecture behavioral of io_controller is
    signal controls_status : controls_status_type := (others => (others => '0'));
    
    signal next_stop : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if RST = '1' then
                controls_status <= (others => (others => '0'));
            else
                out_do_read <= '0';
                if in_command = x"F0" then
                    next_stop <= '1';
                end if;
                if in_new_command = '1' then
                    for K in 0 to CONTROLS_CONTAINER'length - 1 loop
                        for N in 0 to NB_PLAYERS - 1 loop
                            if in_command = CONTROLS_CONTAINER(K, N) then
                                if next_stop = '1' then
                                    controls_status(K)(N) <= '0';
                                    next_stop <= '0';
                                else
                                    controls_status(K)(N) <= '1';
                                end if;
                                
                                out_do_read <= '1';
                            end if;
                        end loop;
                    end loop;  
                end if;
            end if;
        end if;
    end process;
    
    out_control_status <= controls_status(in_requested_command)(in_requested_player);
end behavioral;