library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;

entity collision_detector_rect_rect is
    port(
        o_pos, t_pos : in vector;
        o_dim, t_dim : in vector;

        -- Are two blocks colliding signal
        is_colliding : out std_logic := '0'
    );
end collision_detector_rect_rect;


architecture behavioral of collision_detector_rect_rect is
    signal collisions : std_logic_vector(3 downto 0) := (others => '0');
begin
    -- Is colliding ?
    process(o_pos, t_pos, o_dim, t_dim)
    begin
        if (t_pos.x + t_dim.x) > o_pos.x then
            collisions(D_UP) <= '1';
        end if;

        if (t_pos.y + t_dim.y) > o_pos.y then
            collisions(D_RIGHT) <= '1';
        end if;

        if (o_pos.x + o_dim.x) > t_pos.x then
            collisions(D_DOWN) <= '1';
        end if;

        if (o_pos.y + o_dim.y) > t_pos.y then
            collisions(D_LEFT) <= '1';
        end if;
    end process;

    is_colliding <= collisions(0)
        and collisions(1)
        and collisions(2)
        and collisions(3);
end behavioral;
