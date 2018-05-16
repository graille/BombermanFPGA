library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

entity millisecond_counter is
    generic(
        DATA_LENGTH : integer := 32 -- 32 bits = 4294967295 rising edges
    );
    port(
        CLK, RST : in std_logic;
        timer : out integer range 0 to 2**DATA_LENGTH - 1
    );
end millisecond_counter;

architecture behavioral of millisecond_counter is
    signal tmp : integer range 0 to 2**DATA_LENGTH - 1 := 0;
begin
    process(CLK)

    begin
        if rising_edge(CLK) then
            if RST = '1' then
                tmp <= 0;
            else
                tmp <= (tmp + 1) mod (2**DATA_LENGTH - 1);
            end if;
        end if;
    end process;

    timer <= tmp;
end behavioral;
