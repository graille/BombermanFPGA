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
        out_command : out std_logic := '0'
    );
end io_controller;

architecture behavioral of io_controller is
    type controls_status_type is array(CONTROLS_CONTAINER'length - 1 downto 0) of std_logic_vector(NB_PLAYERS - 1 downto 0);
    signal controls_status : controls_status_type := (others => (others => '0'));
    
    signal next_stop : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if RST = '1' then
                controls_status <= (others => (others => '0'));
            else
                controls_status <= (others => (others => '0'));
                
                if in_new_command = '1' then
                    for K in 0 to CONTROLS_CONTAINER'length - 1 loop
                        for N in 0 to NB_PLAYERS - 1 loop
                            if in_command = CONTROLS_CONTAINER(K, N) then
                                controls_status(K)(N) <= '1';
                            else
                                null;
                            end if;
                        end loop;
                    end loop;  
                end if;
            end if;
        end if;
    end process;
    
    out_command <= controls_status(in_requested_command)(in_requested_player);
end behavioral;