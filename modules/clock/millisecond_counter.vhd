library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity millisecond_counter is
    generic(
        DATA_LENGTH : integer := 21; -- 21 bits = 34 minutes
        FREQUENCY : integer := 100000000
    );
    port(
        CLK, RST : in std_logic;
        timer : out integer range 0 to 2**DATA_LENGTH - 1
    );
end millisecond_counter;

architecture behaviorial of millisecond_counter is
    constant FREQUENCY_DIV : integer := FREQUENCY / 1000;
    signal millisecond : integer range 0 to (2**DATA_LENGTH - 1) := 0;
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
                    millisecond <= (millisecond + 1) mod 2**DATA_LENGTH;
                end if;
            end if;
        end if;

        timer <= millisecond;
    end process;
end architecture;
