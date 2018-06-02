library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;

entity player_to_grid is
    port (
        clk : in std_logic;
        in_player_position : in vector;

        out_position : out grid_position
    );
end player_to_grid;

architecture behavioral of player_to_grid is
    constant HALF_DEFAULT_PLAYER_HITBOX_X : integer := DEFAULT_PLAYER_HITBOX.X / 2;
    constant HALF_DEFAULT_PLAYER_HITBOX_Y : integer := DEFAULT_PLAYER_HITBOX.Y / 2;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            out_position.i <= (in_player_position.X + HALF_DEFAULT_PLAYER_HITBOX_X) / DEFAULT_BLOCK_SIZE_X;
            out_position.j <= (in_player_position.Y + HALF_DEFAULT_PLAYER_HITBOX_Y) / DEFAULT_BLOCK_SIZE_Y;
        end if;
    end process;
end behavioral;
