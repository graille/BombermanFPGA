library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;

entity graphic_controller is
    port(
        CLK, RST : in std_logic;

        in_block : in block_type;

        out_request_pos : out grid_position;

        out_pixel_value : out std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
        out_pixel_position : out screen_position_type;

        -- Players informations
        in_players_position : in players_positions_type;
        in_players_status : in players_status_type;
        in_players_alive : in std_logic_vector(NB_PLAYERS - 1 downto 0)
    );
end graphic_controller;

architecture behavioral of graphic_controller is
    type process_state_type is (
        START_STATE,
        ROTATE_BLOCK_STATE,
        ROTATE_CHARACTER_STATE,
        WRITE_BLOCK_STATE,
        WRITE_CHARACTER_STATE
    );

    type block_position_type is record
        X : integer range 0 to BLOCK_GRAPHIC_HEIGHT - 1;
        Y : integer range 0 to BLOCK_GRAPHIC_WIDTH - 1;

        -- Info :
        -- O-------> Y axis
        -- |
        -- |
        -- X axis
    end record;
    constant DEFAULT_BLOCK_POSITION : block_position_type := (0, 0);
    constant DEFAULT_LAST_BLOCK_POSITION : block_position_type := (BLOCK_GRAPHIC_HEIGHT - 1, BLOCK_GRAPHIC_WIDTH - 1);

    type character_position_type is record
        X : integer range 0 to CHARACTER_HEIGHT - 1;
        Y : integer range 0 to CHARACTER_WIDTH - 1;
    end record;
    constant DEFAULT_CHARACTER_POSITION : character_position_type := (CHARACTER_HEIGHT - 1, CHARACTER_WIDTH - 1);
    constant DEFAULT_LAST_CHARACTER_POSITION : character_position_type := (0, 0);

    -- Grid signals
    signal current_state, next_state : process_state_type := START_STATE;
    signal current_grid_position, next_grid_position : grid_position := (0, 0);

    -- Blocks sprites signals
    signal current_block_position, next_block_position : block_position_type := DEFAULT_BLOCK_POSITION;

    signal block_id : block_category_type := 0;
    signal block_state : state_type := 0;
    signal block_direction : direction_type := D_DOWN;

    signal block_row : integer range 0 to BLOCK_GRAPHIC_HEIGHT - 1 := 0;
    signal block_col : integer range 0 to BLOCK_GRAPHIC_WIDTH - 1 := 0;

    signal block_current_color : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

    -- Characters signals
    signal current_character_position, next_character_position : character_position_type := DEFAULT_CHARACTER_POSITION;
    signal current_character_nb, next_character_nb : integer range 0 to NB_PLAYERS - 1 := 0;

    signal character_id : character_id_type := 0;
    signal character_state : state_type := 0;
    signal character_direction : direction_type := D_DOWN;

    signal character_row : integer range 0 to CHARACTER_HEIGHT - 1 := 0;
    signal character_col : integer range 0 to CHARACTER_WIDTH - 1 := 0;

    signal character_current_color : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

    -- Constants
    constant TRANSPARENT_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '1');
    constant BACKGROUND_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := "01010";
begin
    out_request_pos <= next_grid_position;

    -- This ROM contains all blocks sprites
    RESSOURCES_ROM_INSTANCE:entity work.ressources_sprite_rom
    port map (
        clk => clk,

        in_sprite_id => block_id,
        in_sprite_state => block_state,
        in_sprite_direction => block_direction,

        in_sprite_row => block_row,
        in_sprite_col => block_col,

        out_color => block_current_color
    );

    -- This ROM contains all characters sprites
    CHARACTERS_ROM_INSTANCE:entity work.characters_sprite_rom
    port map (
        clk => clk,

        in_sprite_id => character_id,
        in_sprite_state => character_state,
        in_sprite_direction => character_direction,

        in_sprite_row => character_row,
        in_sprite_col => character_col,

        out_color => character_current_color
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_grid_position <= (others => 0);
                current_state <= START_STATE;

                current_block_position <= DEFAULT_BLOCK_POSITION;
                current_character_position <= DEFAULT_CHARACTER_POSITION;
            else
                current_grid_position <= next_grid_position;
                current_state <= next_state;

                current_block_position <= next_block_position;
                current_character_position <= next_character_position;
            end if;
        end if;
    end process;

    process(in_block, current_state, next_block_position, current_block_position,
        current_grid_position, next_grid_position,
        block_current_color)

        constant VECTOR_HEIGHT_FACTOR : integer := FRAME_HEIGHT / (2**VECTOR_PRECISION);
        constant VECTOR_WIDTH_FACTOR : integer := FRAME_WIDTH / (2**VECTOR_PRECISION);
    begin
        if rst = '1' then
            next_state <= START_STATE;
            next_grid_position <= DEFAULT_GRID_POSITION;

            next_block_position <= DEFAULT_BLOCK_POSITION;
            next_character_position <= DEFAULT_CHARACTER_POSITION;

            next_character_nb <= 0;
        else
            case current_state is
                when START_STATE =>
                    -- Variables reinitialisation
                    next_grid_position <= DEFAULT_GRID_POSITION;

                    next_block_position <= DEFAULT_BLOCK_POSITION;
                    next_character_position <= DEFAULT_CHARACTER_POSITION;

                    next_character_nb <= 0;

                    -- Go to next state
                    next_state <= WRITE_BLOCK_STATE;
                when ROTATE_BLOCK_STATE =>
                    if current_grid_position = DEFAULT_LAST_GRID_POSITION then
                        next_grid_position <= DEFAULT_GRID_POSITION;
                        next_block_position <= DEFAULT_BLOCK_POSITION;

                        next_state <= WRITE_CHARACTER_STATE;
                    else
                        next_block_position <= DEFAULT_BLOCK_POSITION;
                        next_grid_position <= INCR_POSITION_LINEAR(current_grid_position);

                        next_state <= WRITE_BLOCK_STATE;
                    end if;
                when ROTATE_CHARACTER_STATE =>
                    if next_character_nb < NB_PLAYERS - 1 then
                        next_character_nb <= current_character_nb + 1;
                        next_character_position <= DEFAULT_CHARACTER_POSITION;
                        next_state <= WRITE_CHARACTER_STATE;
                    else
                        next_state <= START_STATE;
                    end if;
                when WRITE_BLOCK_STATE =>
                    if block_current_color /= TRANSPARENT_COLOR then
                        out_pixel_value <= block_current_color;
                    else
                        out_pixel_value <= BACKGROUND_COLOR;
                    end if;

                    out_pixel_position.X <= current_grid_position.i * BLOCK_GRAPHIC_HEIGHT + current_block_position.X;
                    out_pixel_position.Y <= current_grid_position.j * BLOCK_GRAPHIC_WIDTH + current_block_position.Y;

                    -- Map sprites ROM entries
                    block_id <= in_block.category;
                    block_state <= in_block.state;
                    block_direction <= in_block.direction;

                    block_row <= current_block_position.X;
                    block_col <= current_block_position.Y;

                    -- Update state
                    if current_block_position = DEFAULT_LAST_BLOCK_POSITION then
                        next_state <= ROTATE_BLOCK_STATE;
                    else
                        if current_block_position.Y = BLOCK_GRAPHIC_WIDTH - 1 then
                            next_block_position.Y <= 0;
                            next_block_position.X <= current_block_position.X + 1;
                        else
                            next_block_position.Y <= current_block_position.Y + 1;
                        end if;
                    end if;
                when WRITE_CHARACTER_STATE =>
                    if in_players_alive(current_character_nb) = '1' then
                        if character_current_color /= TRANSPARENT_COLOR then
                            out_pixel_value <= character_current_color;
                        end if;

                        -- Calculate current pixel position
                        out_pixel_position.X <= (in_players_position(current_character_nb).X * VECTOR_HEIGHT_FACTOR) + current_character_position.X;
                        out_pixel_position.Y <= (in_players_position(current_character_nb).Y * VECTOR_WIDTH_FACTOR) + current_character_position.Y;

                        -- Map characters ROM entries
                        character_id <= in_players_status(current_character_nb).id;
                        character_state <= in_players_status(current_character_nb).state;
                        character_direction <= in_players_status(current_character_nb).direction;

                        character_row <= current_character_position.X;
                        character_col <= current_character_position.Y;

                        -- Update state
                        if current_character_position = DEFAULT_LAST_CHARACTER_POSITION then
                            next_state <= ROTATE_CHARACTER_STATE;
                        else
                            if current_character_position.Y = 0 then
                                next_block_position.Y <= CHARACTER_WIDTH - 1;
                                next_block_position.X <= current_character_position.X - 1;
                            else
                                next_block_position.Y <= current_character_position.Y - 1;
                            end if;
                        end if;
                    end if;
                when others => null;
            end case;
        end if;
    end process;
end behavioral;
