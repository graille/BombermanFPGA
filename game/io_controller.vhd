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

        in_command : in std_logic_vector(15 downto 0);
        out_command : out io_signal
    );
end io_controller;

architecture behavioral of io_controller is
    type controls_status_type is array(CONTROLS_CONTAINER'length - 1 downto 0) of std_logic_vector(NB_PLAYERS - 1 downto 0);
    signal controls_status : controls_status_type := (others => (others => '0'));
    
    -- Rotate signals
    signal current_command : integer range 0 to CONTROLS_CONTAINER'length - 1 := 0;
    signal current_player : integer range 0 to NB_PLAYERS - 1 := 0;

    signal command_reg : std_logic_vector(15 downto 0) := (others => '0');
    signal next_stop : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if RST = '1' then
                controls_status <= (others => (others => '0'));
                current_command <= 0; 
                current_player <= 0;
            else
                -- Check and update each commands
                command_reg <= in_command;
                
                for K in 0 to CONTROLS_CONTAINER'length - 1 loop
                    for N in 0 to NB_PLAYERS - 1 loop
                        if command_reg(7 downto 0) = x"F0" then
                            next_stop <= '1';
                        else 
                            if command_reg(7 downto 0) = CONTROLS_CONTAINER(K)(N) then
                                if next_stop = '1' then
                                    controls_status(K)(N) <= '0';
                                    next_stop <= '0';
                                else
                                    controls_status(K)(N) <= '1';
                                end if;
                            end if;
                        end if;
                    end loop;
                end loop;  
                
                -- Rotate current command
                if current_command = (CONTROLS_CONTAINER'length - 1) and current_player = (NB_PLAYERS - 1) then
                    current_command <= 0;
                    current_player <= 0;
                elsif current_player = NB_PLAYERS - 1 then
                    current_player <= 0;
                    current_command <= current_command + 1;
                else
                    current_player <= current_player + 1;
                end if;
            end if;
        end if;
    end process;
 
    -- Output multiplexer
    process(controls_status, current_command, current_player)
    begin
        if controls_status(current_command)(current_player) = '1' then
            out_command <= CONTROLS_CONTAINER(current_command)(current_player);
        else
            out_command <= x"00";
        end if;
    end process;
end behavioral;