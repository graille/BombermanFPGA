library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;

entity collision_detector_rect_rect is
    port(
        clk : in std_logic;
        r1_pos, r2_pos : in vector;
        r1_dim, r2_dim : in vector;

        -- Are two blocks colliding ?
        are_colliding : out std_logic := '0'
    );
end collision_detector_rect_rect;

architecture behavioral of collision_detector_rect_rect is
    signal collisions : std_logic_vector(3 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            collisions <= (others => '0');
            if (r2_pos.x + r2_dim.x) > r1_pos.x then
                collisions(D_UP) <= '1';
            else
                collisions(D_UP) <= '0';
            end if;

            if (r2_pos.y + r2_dim.y) > r1_pos.y then
                collisions(D_LEFT) <= '1';
            else
                collisions(D_LEFT) <= '0';
            end if;

            if (r1_pos.x + r1_dim.x) > r2_pos.x then
                collisions(D_DOWN) <= '1';
            else
                collisions(D_DOWN) <= '0';
            end if;

            if (r1_pos.y + r1_dim.y) > r2_pos.y then
                collisions(D_RIGHT) <= '1';
            else
                collisions(D_RIGHT) <= '0';
            end if;
    end if;
    end process;

    are_colliding <= collisions(0)
        and collisions(1)
        and collisions(2)
        and collisions(3);
end behavioral;
