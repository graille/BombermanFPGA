library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;

entity graphic_controller is
    port(
        CLK, RST : in std_logic;

        in_block : in block_type;
        in_players_positions : in array_vector(NB_PLAYERS - 1 downto 0);

        out_request_pos : out grid_position;

        out_pixel_value : out integer range 0 to 4;
        out_pixel_x : out integer range 0 to FRAME_WIDTH - 1;
        out_pixel_y : out integer range 0 to FRAME_HEIGHT - 1
    );
end graphic_controller;

architecture behaviorial of graphic_controller is
    type state_type is (
        START_STATE,
        ROTATE_STATE,
        CALCULATE_BLOCK_STATE,
        CALCULATE_PLAYER_STATE
    );

    signal current_state, next_state : state_type := START_STATE;
    signal current_grid_position, next_grid_position : grid_position := (0, 0);

    type block_position_type is record
        X : integer range 0 to BLOCK_HEIGHT - 1;
        Y : range 0 to BLOCK_WIDTH - 1;

        -- Info :
        -- O-------> Y axis
        -- |
        -- |
        -- X axis
    end record;

    -- Blocks signals
    signal current_block_position, next_block_position : block_position_type := (0, 0);

    -- Sprites signals
    signal sprite_nb : integer range 0 to 127;
    signal sprite_row : integer range 0 to 127;
    signal sprite_col : integer range 0 to 127;

    signal sprite_current_color : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

    constant TRANSPARENT_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '1');
    constant BACKGROUND_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := '01010';
begin
    out_request_pos <= next_pos;

    SPRITE_ROM_INSTANCE:entity work.sprite_rom
    port map (
        clk => clk,

        in_sprite_nb => sprite_nb,
        in_sprite_row => sprite_row,
        in_sprite_col => sprite_col,

        out_color => sprite_current_color
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_grid_position <= (others => 0);
                current_state <= START_STATE;
                current_block_position <= (0, 0);
            else
                current_grid_position <= next_grid_position;
                current_state <= next_state;
                current_block_position <= next_block_position;
            end if;
        end if;
    end process;

    process(in_block, current_state, next_block_position, current_block_position,
        current_grid_position, next_grid_position,
        sprite_current_color)
    begin
        if rst = '1' then
            next_state <= START_STATE;
            next_grid_position <= (0, 0);
            next_block_position <= (0, 0);
        else
            case current_state is
                when START_STATE =>
                    next_state <= ROTATE_STATE;
                when ROTATE_STATE =>
                    next_pos <= INCR_POSITION_LINEAR(current_pos);
                    next_state <= CALCULATE_BLOCK_STATE;
                    next_block_position <= (0, 0);
                when CALCULATE_BLOCK_STATE =>
                    -- This state calculate pixels of a grid
                    -- Calculate pixel
                    if sprite_current_color /= TRANSPARENT_COLOR then
                        out_pixel_value <= sprite_current_color;
                    else
                        out_pixel_value <= BACKGROUND_COLOR;
                    end if;

                    out_pixel_x <= current_grid_position.i * BLOCK_HEIGHT + current_block_position.X;
                    out_pixel_y <= current_grid_position.j * BLOCK_WIDTH + current_block_position.Y;

                    -- Map sprites ROM entries
                    sprite_nb <= in_block.category;
                    sprite_row <= next_block_position.X;
                    sprite_col <= next_block_position.Y;

                    -- Update state
                    if (current_block_position.Y = BLOCK_WIDTH - 1) and (current_block_position.X = BLOCK_HEIGHT - 1) then
                        next_block_position <= (0, 0);
                        next_state <= ROTATE_STATE;
                    else
                        if current_block_position.Y = BLOCK_WIDTH - 1 then
                            next_block_position.Y <= 0;
                            next_block_position.X <= current_block_position.X + 1;
                        else
                            next_block_position.Y <= current_block_position.Y + 1;
                        end if;
                    end if;
                when CALCULATE_PLAYER_STATE =>
                    -- TODO
                    null;
                when others => null;
            end case;
        end if;
    end process;

end architecture;
