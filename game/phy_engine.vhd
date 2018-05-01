library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;

entity collision_detector_rect_rect is
    port(
        x_pos, y_pos : in vector;
        x_dim, y_dim : in vector;
        is_colliding : out std_logic := '0';
        collision_face : out positive range 0 to 3
    );
end collision_detector_rect_rect;


architecture behavioural of collision_detector_rect_rect is
begin
    process(x_pos, y_pos, x_dim, y_dim)
    begin
    
    end process;
end architecture;
