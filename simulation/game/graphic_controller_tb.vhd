library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity graphic_controller_tb is
end graphic_controller_tb;

architecture behavioural of graphic_controller_tb is
    constant PERIOD : time := 12.5ns;
    signal clk, rst : std_logic := '0';
    signal in_block            : block_type;

    signal out_request_pos     : grid_position;
    signal out_pixel_value     : pixel_value_type := DEFAULT_PIXEL_VALUE;
    signal out_pixel_position  : screen_position_type := DEFAULT_SCREEN_POSITION;
    signal out_write_pixel     : std_logic := '0';
begin
    clk <= not(clk) after PERIOD/2;
    graphic_controller_i : entity work.graphic_controller
        port map (
            CLK => CLK,
            RST                 => RST,
            in_block            => in_block,

            out_request_pos     => out_request_pos,

            out_pixel_value     => out_pixel_value,
            out_pixel_position  => out_pixel_position,
            out_write_pixel     => out_write_pixel,

            in_player_position => (others => 0),
            in_player_status   => DEFAULT_PLAYER_STATUS,
            in_player_alive    => '0'
        );

    -- RAM simulation
    process(clk)
        variable nb : integer := 0;
    begin
        if rising_edge(clk) then
            in_block <= (nb mod 32, out_request_pos.i, out_request_pos.j, 0, 0);
            nb := nb + 1;
        end if;
    end process;
end behavioural;
