library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_RECT_PKG.all;

entity collision_detector_rect_rect is
    port(
        o_pos, t_pos : in vector;
        o_dim, t_dim : in vector;
        is_colliding : out std_logic := '0'
    );
end collision_detector_rect_rect;


architecture behavioural of collision_detector_rect_rect is
    signal collisions : std_logic_vector(3 downto 0) := (others => '0');
begin
    -- Is colliding ?
    process(o_pos, t_pos, o_dim, t_dim)
    begin
        if ((t_pos(1) + t_dim(1)) > o_pos(1)) then
            collisions(0) <= '1';
        end if;

        if ((t_pos(0) + t_dim(0)) > o_pos(0)) then
            collisions(1) <= '1';
        end if;

        if ((o_pos(1) + o_dim(1)) > t_pos(1)) then
            collisions(2) <= '1';
        end if;

        if ((o_pos(0) + o_dim(0)) > t_pos(1)) then
            collisions(3) <= '1';
        end if;
    end process;

    is_colliding <= collisions(0)
        and collisions(1)
        and collisions(2)
        and collisions(3);
end architecture;
