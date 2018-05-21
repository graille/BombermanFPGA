library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity clk_divider is
    generic (
        N : integer := 2
    );
    port (
        clk, rst: in std_logic;
        clock_out: out std_logic
    );
end clk_divider;

architecture behavioral of clk_divider is
    signal count: integer:=1;
    signal tmp : std_logic := '0';
begin
    process(clk, rst)
    begin
        if rst = '1' then
            count <= 1;
            tmp <= '0';
        elsif rising_edge(clk) then
            count <= count+1;
            if (count = N) then
                tmp <= NOT tmp;
                count <= 1;
            end if;
        end if;
        clock_out <= tmp;
    end process;
end behavioral;
