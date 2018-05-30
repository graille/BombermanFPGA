library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;

entity player_to_grid is
    port(
        in_player_position : in vector;

        out_position : out grid_position
    );
end player_to_grid;

architecture behavioral of player_to_grid is
    constant FACTOR_HEIGHT : integer := VECTOR_PRECISION_X / (GRID_ROWS + 1);
    constant FACTOR_WIDTH : integer := VECTOR_PRECISION_Y / GRID_COLS;
begin
    out_position.i <= (in_player_position.X + (DEFAULT_PLAYER_HITBOX.X / 2)) / FACTOR_HEIGHT + 1;
    out_position.j <= (in_player_position.Y + (DEFAULT_PLAYER_HITBOX.Y / 2)) / FACTOR_WIDTH + 1;
end behavioral;
