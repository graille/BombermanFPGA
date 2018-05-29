--
-- Author : Thibault PIANA
-- This module return the number of milliseconds since the last reset
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;

entity millisecond_counter is
    generic(
        FREQUENCY : integer := 80000000
    );
    port(
        CLK, RST : in std_logic;
        timer : out millisecond_count
    );
end millisecond_counter;

architecture behavioral of millisecond_counter is
    constant FREQUENCY_DIV : integer := FREQUENCY / 1000;
    signal millisecond : millisecond_count := 0;
    signal tmp : integer range 0 to (FREQUENCY_DIV - 1) := 0;
begin
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                tmp <= 0;
                millisecond <= 0;
            else
                tmp <= (tmp + 1) mod FREQUENCY_DIV;
                if tmp = 0 then
                    millisecond <= (millisecond + 1) mod 2**MILLISECOND_COUNTER_PRECISION;
                end if;
            end if;
        end if;
    end process;
    
    timer <= millisecond;
end behavioral;
