library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity millisecond_counter is
    generic(
        FREQUENCY : integer := 100000000
    );
    port(
        CLK, RST : in std_logic;
        timer : out millisecond_count
    );
end millisecond_counter;

architecture behaviorial of millisecond_counter is
    constant FREQUENCY_DIV : integer := FREQUENCY / 1000;
    signal millisecond : millisecond_count := 0;
begin
    process(CLK)
        variable tmp : integer range 0 to (FREQUENCY_DIV - 1) := 0;
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                tmp := 0;
                millisecond <= 0;
            else
                tmp := (tmp + 1) mod FREQUENCY_DIV;
                if tmp = 0 then
                    millisecond <= (millisecond + 1) mod 2**MILLISECOND_COUNTER_PRECISION;
                end if;
            end if;
        end if;

        timer <= millisecond;
    end process;
end architecture;
