library ieee;
use ieee.std_logic_1164.all;

entity simple_prng_lfsr is
    generic(
        DATA_LENGTH : integer := 9 -- Number of random bits
        SEED_LENGTH : integer := 16
    )
    port (
        clk, rst : in  std_logic;
        seed : in std_logic_vector(SEED_LENGTH - 1 downto 0);

        random_output : out unsigned(DATA_LENGTH - 1 downto 0);
        percent : out integer range 0 to 100
    );
end entity;

architecture rtl of lfsr_bit is
    signal lfsr       : std_logic_vector (DATA_LENGTH - 1 downto 0);
    signal feedback  : std_logic;

begin
    -- Option for LFSR size 4
    feedback <= not(lfsr(3) xor lfsr(2));

    sr_pr : process (clk)
        begin
            if (rising_edge(clk)) then
                if (reset = '1') then
                    lfsr <= resize(seed, lfsr'length);
                else
                    lfsr <= lfsr(DATA_LENGTH - 2 downto 0) & feedback;
                end if;
            end if;
    end process sr_pr;

    random_output <= unsigned(lfsr);
    percent <= to_integer(unsigned(lfsr) * 100) / (2**DATA_LENGTH);

end architecture;
