library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simple_prng_lfsr is
    generic(
        DATA_LENGTH : integer := 32; -- Number of random bits
        SEED_LENGTH : integer := 16
    );
    port (
        clk, rst : in  std_logic;
        in_seed : in std_logic_vector(SEED_LENGTH - 1 downto 0) := (others => '0');

        random_output : out std_logic_vector(DATA_LENGTH - 1 downto 0);
        percent : out integer range 0 to 100
    );
end entity;

architecture behavioral of simple_prng_lfsr is
    signal lfsr       : std_logic_vector(DATA_LENGTH - 1 downto 0) := (others => '0');
    signal feedback   : std_logic;
begin
    -- Option for LFSR size 4
    feedback <= not(lfsr(3) xor lfsr(2));

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                lfsr <= std_logic_vector(resize(unsigned(in_seed), DATA_LENGTH));
            else
                lfsr <= lfsr(DATA_LENGTH - 2 downto 0) & feedback;
            end if;
        end if;
    end process;

    random_output <= lfsr;
    percent <= to_integer((unsigned(lfsr) * 100) srl DATA_LENGTH);
end behavioral;
