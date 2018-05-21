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
        ROTATE_STATE,
        CALCULATE_BLOCK_STATE,
        CALCULATE_PLAYER_STATE
    );

    signal current_state, next_state : process_state_type := START_STATE;
    signal current_grid_position, next_grid_position : grid_position := (0, 0);

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

    -- Blocks signals
    signal current_block_position, next_block_position : block_position_type := DEFAULT_BLOCK_POSITION;
    signal next_pos, current_pos : grid_position := DEFAULT_GRID_POSITION;
    
    -- Sprites signals
    signal sprite_id : block_category_type := 0;
    signal sprite_state : state_type := 0;
    signal sprite_direction : direction_type := D_DOWN;
    
    signal sprite_row : integer range 0 to 127;
    signal sprite_col : integer range 0 to 127;

    signal sprite_current_color : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

    -- Characters signals
    
    -- Constants
    constant TRANSPARENT_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '1');
    constant BACKGROUND_COLOR : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := "01010";
begin
    out_request_pos <= next_pos;

    RESSOURCES_ROM_INSTANCE:entity work.ressources_sprite_rom
    port map (
        clk => clk,

        in_sprite_id => sprite_id,
        in_sprite_state => sprite_state,
        in_sprite_direction => sprite_direction,
        
        in_sprite_row => sprite_row,
        in_sprite_col => sprite_col,

        out_color => sprite_current_color
    );
    
    --CHARACTERS_ROM_INSTANCE:entity work.characters_sprite_rom
    --port map (
    --    clk => clk,

    --    in_sprite_id => sprite_id,
    --    in_sprite_state => sprite_state,
    --    in_sprite_direction => sprite_direction,
        
    --    in_sprite_row => sprite_row,
    --    in_sprite_col => sprite_col,

    --    out_color => sprite_current_color
    --);
    

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
            next_grid_position <= DEFAULT_GRID_POSITION;
            next_block_position <= DEFAULT_BLOCK_POSITION;
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

                    out_pixel_position.X <= current_grid_position.i * BLOCK_GRAPHIC_HEIGHT + current_block_position.X;
                    out_pixel_position.Y <= current_grid_position.j * BLOCK_GRAPHIC_WIDTH + current_block_position.Y;

                    -- Map sprites ROM entries
                    sprite_id <= in_block.category;
                    sprite_state <= in_block.state;
                    sprite_direction <= in_block.direction;
                    
                    sprite_row <= next_block_position.X;
                    sprite_col <= next_block_position.Y;

                    -- Update state
                    if (current_block_position.Y = BLOCK_GRAPHIC_WIDTH - 1) and (current_block_position.X = BLOCK_GRAPHIC_HEIGHT - 1) then
                        next_block_position <= (0, 0);
                        next_state <= ROTATE_STATE;
                    else
                        if current_block_position.Y = BLOCK_GRAPHIC_WIDTH - 1 then
                            next_block_position.Y <= 0;
                            next_block_position.X <= current_block_position.X + 1;
                        else
                            next_block_position.Y <= current_block_position.Y + 1;
                        end if;
                    end if;
                when CALCULATE_PLAYER_STATE =>

                    null;
                when others => null;
            end case;
        end if;
    end process;
end behavioral;
