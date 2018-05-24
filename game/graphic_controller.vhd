library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_DIRECTION_PKG.all;
use work.PROJECT_POS_FUNCTIONS_PKG.all;

entity graphic_controller is
    port(
        CLK, RST : in std_logic;

        in_block : in block_type;

        out_request_pos : out grid_position;

        out_pixel_value : out pixel_value_type := DEFAULT_PIXEL_VALUE;
        out_pixel_position : out screen_position_type := DEFAULT_SCREEN_POSITION;
        out_write_pixel : out std_logic := '0';

        -- Players informations
        in_players_position : in players_positions_type;
        in_players_status : in players_status_type;
        in_players_alive : in std_logic_vector(NB_PLAYERS - 1 downto 0)
    );
end graphic_controller;

architecture behavioral of graphic_controller is
    type process_state_type is (
        START_STATE,
        
        -- Write blocks
        ROTATE_BLOCK_STATE,
        WRITE_BLOCK_STATE,
        
        -- Write characters
        ROTATE_CHARACTER_STATE,
        WRITE_CHARACTER_STATE,
        
        -- Write time
        WRITE_TIME_REMAINING_ROTATE_STATE,
        WRITE_TIME_REMAINING_STATE,
        
        -- Test state
        TEST
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
    signal current_grid_position, next_grid_position : grid_position := DEFAULT_GRID_POSITION;

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
    
    signal next_pixel_position, current_pixel_position: screen_position_type := DEFAULT_SCREEN_POSITION;
    signal write_pixel, write_pixel_reg : std_logic := '0';
begin
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

    -- State saver
    process(clk)
    begin
        if rising_edge(clk) then
            current_grid_position <= next_grid_position;
            current_state <= next_state;

            current_block_position <= next_block_position;
            current_character_position <= next_character_position;
            
            current_pixel_position <= next_pixel_position;
            
            write_pixel_reg <= write_pixel;
        end if;
    end process;

    -- Out color multiplexer
    process(block_current_color, character_current_color, current_state, current_pixel_position)
    begin
        case current_state is
            when TEST =>
                out_pixel_value <= std_logic_vector(to_unsigned(current_pixel_position.X mod 32, COLOR_BIT_PRECISION));
            when WRITE_BLOCK_STATE | ROTATE_BLOCK_STATE =>
                if block_current_color /= TRANSPARENT_COLOR then
                    out_pixel_value <= block_current_color;
                else
                    out_pixel_value <= BACKGROUND_COLOR;
                end if;
            when WRITE_CHARACTER_STATE | ROTATE_CHARACTER_STATE =>
                out_pixel_value <= character_current_color;
            when others => 
                out_pixel_value <= BACKGROUND_COLOR;
        end case;
    end process;

    -- Control signals controller
    process(
        rst,
        clk,
        in_block, 
        current_state, 
        
        current_block_position,
        current_grid_position,
        current_pixel_position,
        
        write_pixel_reg)

        constant VECTOR_HEIGHT_FACTOR : integer := FRAME_HEIGHT / (2**VECTOR_PRECISION);
        constant VECTOR_WIDTH_FACTOR : integer := FRAME_WIDTH / (2**VECTOR_PRECISION);
    begin
        if rst = '1' then
            next_state <= START_STATE;
            next_grid_position <= DEFAULT_GRID_POSITION;

            next_block_position <= DEFAULT_BLOCK_POSITION;
            next_character_position <= DEFAULT_CHARACTER_POSITION;
            
            next_pixel_position <= DEFAULT_SCREEN_POSITION;

            next_character_nb <= 0;
            
            write_pixel <= '0';
        else
            write_pixel <= '0';
            if current_state = START_STATE then
                    -- Variables reinitialisation
                    next_grid_position <= DEFAULT_GRID_POSITION;

                    next_block_position <= DEFAULT_BLOCK_POSITION;
                    next_character_position <= DEFAULT_CHARACTER_POSITION;

                    next_character_nb <= 0;
                    write_pixel <= '0';

                    -- Go to next state
                    next_state <= TEST;
            end if;
            if current_state = ROTATE_BLOCK_STATE then
                    if current_grid_position = DEFAULT_LAST_GRID_POSITION then
                        next_grid_position <= DEFAULT_GRID_POSITION;
                        next_block_position <= DEFAULT_BLOCK_POSITION;
            
                        --next_state <= WRITE_CHARACTER_STATE;
                        next_state <= START_STATE;
                    else
                        next_block_position <= DEFAULT_BLOCK_POSITION;
                        next_grid_position <= INCR_POSITION_LINEAR(current_grid_position);
                        
                        next_state <= WRITE_BLOCK_STATE;
                    end if;
            end if;
            if current_state = WRITE_BLOCK_STATE then
                    write_pixel <= '1';

                    next_pixel_position.X <= (current_grid_position.i * BLOCK_GRAPHIC_HEIGHT) + current_block_position.X;
                    next_pixel_position.Y <= (current_grid_position.j * BLOCK_GRAPHIC_WIDTH) + current_block_position.Y;

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
                            next_block_position.X <= current_block_position.X;
                            next_block_position.Y <= current_block_position.Y + 1;
                        end if;
                    end if;
            end if;
            if current_state = TEST then
                    write_pixel <= '1';
                    
                    if current_pixel_position = DEFAULT_LAST_SCREEN_POSITION then
                        next_pixel_position <= DEFAULT_SCREEN_POSITION;
                    else
                        if current_pixel_position.Y = FRAME_WIDTH - 1 then
                            next_pixel_position.Y <= 0;
                            next_pixel_position.X <= current_pixel_position.X + 1;
                        else
                            next_pixel_position.X <= current_pixel_position.X;
                            next_pixel_position.Y <= current_pixel_position.Y + 1;
                        end if;
                    end if;
            end if;
        end if;
    end process;
    
    out_pixel_position <= current_pixel_position;
    out_write_pixel <= write_pixel_reg;
    
    out_request_pos <= current_grid_position;
end behavioral;
