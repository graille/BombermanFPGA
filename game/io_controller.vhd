library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity io_controller is
    generic(
        FREQUENCY : integer := 80000000
    );
    port(
        CLK, RST : in std_logic;

        in_command : in std_logic_vector(15 downto 0);
        out_command : out io_signal
    );
end io_controller;

architecture behavioral of io_controller is
    type commands_time_array_type is array(0 to NB_PLAYERS - 1) of millisecond_count;
    type commands_time_container_type is array(0 to 4) of commands_time_array_type;
    signal millisecond_container : commands_time_container_type := (others => (others => 0));
    signal millisecond : millisecond_count := 0;
    
    type controls_status_type is array(CONTROLS_CONTAINER'length - 1 downto 0) of std_logic_vector(NB_PLAYERS - 1 downto 0);
    
    signal controls_status : controls_status_type := (others => (others => '0'));
    signal controls_active : controls_status_type := (others => (others => '0'));
    
    signal current_command : integer range 0 to CONTROLS_CONTAINER'length - 1 := 0;
    signal current_player : integer range 0 to NB_PLAYERS - 1 := 0;
    
    signal command_reg : std_logic_vector(15 downto 0) := (others => '0');
begin
    COUNTER_ENGINE:entity work.millisecond_counter
    generic map (
        FREQUENCY => FREQUENCY
    )
    port map (
        CLK => CLK,
        RST => RST,
        timer => millisecond
    );
    
    process(clk)
    begin
        if rising_edge(clk) then
            command_reg <= in_command;
        end if;
    end process;
    
    COMMAND_ASSIGNATOR:for K in 0 to CONTROLS_CONTAINER'length - 1 generate
        PLAYER_ASSIGNATION:for N in 0 to NB_PLAYERS - 1 generate
            process(clk)
                variable diff_var : millisecond_count;
            begin
                if rising_edge(clk) then
                    if RST = '1' then
                        controls_status(K)(N) <= '0';
                        controls_active(K)(N) <= '0';
                        millisecond_container(K)(N) <= 0;
                    else
                        if command_reg(7 downto 0) = CONTROLS_CONTAINER(K)(N) then
                            if command_reg(15 downto 8) = x"F0" then
                                controls_status(K)(N) <= '0';
                            else
                                controls_status(K)(N) <= '1';
                                millisecond_container(K)(N) <= millisecond;
                            end if;
                        end if;
                        
                        diff_var := (millisecond - millisecond_container(K)(N));
                        
                        if diff_var > 10 then
                            controls_active(K)(N) <= '1';
                            millisecond_container(K)(N) <= millisecond;
                        else
                            controls_active(K)(N) <= '0';
                        end if;
                    end if;
                end if;
            end process;
        end generate;
    end generate;   
        
    process(controls_status, current_command, current_player)
    begin
        if (controls_status(current_command)(current_player) and controls_active(current_command)(current_player)) = '1' then
            out_command <= CONTROLS_CONTAINER(current_command)(current_player);
        else
            out_command <= x"00";
        end if;
    end process;
        
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_command <= 0;
                current_player <= 0;
            else
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
end behavioral;
