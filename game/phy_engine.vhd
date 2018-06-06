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
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- From https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
            if r1_pos.Y < r2_pos.Y + r2_dim.Y and
                r1_pos.Y + r1_dim.Y > r2_pos.Y and
                r1_pos.X < r2_pos.X + r2_dim.X and
                r1_dim.X + r1_pos.X > r2_pos.X then
                are_colliding <= '1';
            else
                are_colliding <= '0';
            end if;
        end if;
    end process;
end behavioral;
