library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity graphic_controller is
    port(
        CLK, RST : in std_logic;

        in_block : in block_type;

        out_request_pos : out grid_position;

        out_pixel_value : out pixel_value_type := DEFAULT_PIXEL_VALUE;
        out_pixel_position : out screen_position_type := DEFAULT_SCREEN_POSITION;
        out_write_pixel : out std_logic := '0';

        -- Players informations
        out_request_player : out integer range 0 to NB_PLAYERS - 1;
        in_player_position : in vector;
        in_player_status : in player_status_type;
        in_player_alive : in std_logic
    );
end graphic_controller;

architecture behavioral of graphic_controller is
    type process_state_type is (
        START_STATE,

        -- Write blocks
        ROTATE_GRID_STATE,
        WAITING_GRID_STATE,
        WAITING_BLOCK_STATE,
        WRITE_BLOCK_STATE,

        -- Write characters
        ROTATE_CHARACTER_STATE,
        WRITE_CHARACTER_STATE,

        -- Write time
        WRITE_TIME_REMAINING_ROTATE_STATE,
        WRITE_TIME_REMAINING_STATE,

        -- Test state
        TEST,
        STOP_STATE
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
        X : integer range 0 to CHARACTER_GRAPHIC_HEIGHT - 1;
        Y : integer range 0 to CHARACTER_GRAPHIC_WIDTH - 1;
    end record;
    constant DEFAULT_CHARACTER_POSITION : character_position_type := (CHARACTER_GRAPHIC_HEIGHT - 1, CHARACTER_GRAPHIC_WIDTH - 1);
    constant DEFAULT_LAST_CHARACTER_POSITION : character_position_type := (0, 0);

    -- Grid signals
    signal current_state : process_state_type := START_STATE;
    
    -- Blocks sprites signals
    signal current_grid_position : grid_position := DEFAULT_GRID_POSITION;
    signal current_block_position : block_position_type := DEFAULT_BLOCK_POSITION;
    signal current_block : block_type := DEFAULT_BLOCK;

    signal block_current_color : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '0');

    -- Characters signals
    signal current_character_position : character_position_type := DEFAULT_CHARACTER_POSITION;
    signal current_character_nb : integer range 0 to NB_PLAYERS - 1 := 0;
    signal current_character : player_status_type := DEFAULT_PLAYER_STATUS;

    signal character_current_color : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '0');

    signal current_pixel_position: screen_position_type := DEFAULT_SCREEN_POSITION;
begin
    -- This ROM contains all blocks sprites
    RESSOURCES_ROM_INSTANCE:entity work.ressources_sprite_rom
    port map (
        clk => clk,

        in_sprite_id => current_block.category,
        in_sprite_state => current_block.state,
        in_sprite_direction => current_block.direction,

        in_sprite_row => current_block_position.X,
        in_sprite_col => current_block_position.Y,

        out_color => block_current_color
    );

    -- This ROM contains all characters sprites
    CHARACTERS_ROM_INSTANCE:entity work.characters_sprite_rom
    port map (
        clk => clk,

        in_sprite_id => current_character.id,
        in_sprite_state => current_character.state,
        in_sprite_direction => current_character.direction,

        in_sprite_row => current_character_position.X,
        in_sprite_col => current_character_position.Y,

        out_color => character_current_color
    );

    -- Out color multiplexer
    process(block_current_color, character_current_color, current_state, current_pixel_position)
    begin
        case current_state is
            when TEST =>
                out_write_pixel <= '1';
                out_pixel_value <= std_logic_vector(to_unsigned((current_pixel_position.X + current_pixel_position.Y) mod 32, COLOR_BIT_PRECISION));
            when WRITE_BLOCK_STATE =>
                if block_current_color /= TRANSPARENT_COLOR then
                    out_write_pixel <= '1';
                    out_pixel_value <= block_current_color;
                else
                    out_write_pixel <= '1';
                    out_pixel_value <= BACKGROUND_COLOR;
                end if;
            when WRITE_CHARACTER_STATE =>
                if character_current_color /= TRANSPARENT_COLOR then
                    out_write_pixel <= '1';
                    out_pixel_value <= character_current_color;
                else
                    out_write_pixel <= '0';
                    out_pixel_value <= BACKGROUND_COLOR;
                end if;
            when others =>
                out_write_pixel <= '0';
                out_pixel_value <= BACKGROUND_COLOR;
        end case;
    end process;

    out_pixel_position <= current_pixel_position;
    
    out_request_pos <= current_grid_position;
    out_request_player <= current_character_nb;

    -- Control signals controller
    process(clk)
        constant VECTOR_HEIGHT_FACTOR : integer := FRAME_HEIGHT / (2**VECTOR_PRECISION);
        constant VECTOR_WIDTH_FACTOR : integer := FRAME_WIDTH / (2**VECTOR_PRECISION);
        
        variable waiting_clocks : integer range 0 to 15 := 2;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= START_STATE;
                current_grid_position <= DEFAULT_GRID_POSITION;
                current_pixel_position <= DEFAULT_SCREEN_POSITION;

                current_block_position <= DEFAULT_BLOCK_POSITION;
                current_character_position <= DEFAULT_CHARACTER_POSITION;

                current_character_nb <= 0;
            else
                case current_state is
                    when START_STATE =>
                        -- Variables reinitialisation
                        current_grid_position <= DEFAULT_GRID_POSITION;

                        current_block_position <= DEFAULT_BLOCK_POSITION;
                        current_character_position <= DEFAULT_CHARACTER_POSITION;

                        current_character_nb <= 0;

                        -- Go to next state
                        current_state <= WAITING_GRID_STATE;
                    when ROTATE_GRID_STATE =>
                        current_grid_position <= INCR_POSITION_LINEAR(current_grid_position);
                        current_block_position <= DEFAULT_BLOCK_POSITION;

                        if current_grid_position = DEFAULT_LAST_GRID_POSITION then
                            current_state <= START_STATE;
                        else
                            current_state <= WAITING_GRID_STATE;
                        end if;
                    when WAITING_GRID_STATE =>
                        waiting_clocks := waiting_clocks - 1;
                        
                        current_block <= in_block;
                        if waiting_clocks = 0 then
                            waiting_clocks := 2;
                            current_state <= WAITING_BLOCK_STATE;
                        else
                            current_state <= WAITING_GRID_STATE;
                        end if;
                    when WAITING_BLOCK_STATE =>
                        current_state <= WRITE_BLOCK_STATE;
                    when WRITE_BLOCK_STATE =>
                        current_pixel_position.X <= (current_grid_position.i * BLOCK_GRAPHIC_HEIGHT) + current_block_position.X;
                        current_pixel_position.Y <= (current_grid_position.j * BLOCK_GRAPHIC_WIDTH) + current_block_position.Y;

                        -- Update state
                        if current_block_position = DEFAULT_LAST_BLOCK_POSITION then
                            current_state <= ROTATE_GRID_STATE;
                        elsif current_block_position.Y = BLOCK_GRAPHIC_WIDTH - 1 then
                            current_block_position.Y <= 0;
                            current_block_position.X <= current_block_position.X + 1;
                            current_state <= WAITING_BLOCK_STATE;
                        else
                            current_block_position.X <= current_block_position.X;
                            current_block_position.Y <= current_block_position.Y + 1;
                            current_state <= WAITING_BLOCK_STATE;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process;
end behavioral;
