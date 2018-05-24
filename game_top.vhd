library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity GAME_TOP is
    generic (
        FREQUENCY: integer := 80000000;
        NB_SWITCH : integer := 16
    );
    port (
        -- Basic inputs
        CLK100, RST : in std_logic := '0';

        -- Switches (to configure seeds for PRNG)
        SW : in std_logic_vector(NB_SWITCH - 1 downto 0) := (others => '0');

        -- LEDS
        LED : out std_logic_vector(NB_SWITCH - 1 downto 0);

        -- VGA Outputs
        VGA_HS_O : out  STD_LOGIC;
        VGA_VS_O : out  STD_LOGIC;
        VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
        VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
        VGA_G : out  STD_LOGIC_VECTOR (3 downto 0);

        -- Keyboard inputs
        PS2_CLK : in std_logic;
        PS2_DATA : in std_logic;

        SEG : out std_logic_vector(6 downto 0);
        AN : out std_logic_vector(7 downto 0);
        DP : out std_logic;
        UART_TXD : out std_logic
    );
end GAME_TOP;

architecture behavioral of GAME_TOP is
    signal CLK : std_logic := '0';

    -- Signals
    signal current_block : block_type;

    -- Graphic controller
    signal in_block             : block_type;
    signal out_request_pos      : grid_position;
    signal out_pixel_value      : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
    signal out_pixel_position   : screen_position_type;

    signal players_position     : players_positions_type;
    signal players_status       : players_status_type;
    signal players_alive        : std_logic_vector(NB_PLAYERS - 1 downto 0);
    
    signal write_pixel : std_logic := '0';

    -- Game controller
    signal in_read_block     : block_type;

    signal game_end          : std_logic := '0';
    signal game_winner       : integer range 0 to NB_PLAYERS - 1;

    signal out_grid_position : grid_position;
    signal out_block         : block_type;
    signal out_write         : std_logic;

    -- Pixel ram
    signal out_pixel : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

    -- Sprite converter
    signal in_color    : std_logic_vector(4 downto 0);

    -- VGA Controller
    signal CLK_VGA    : std_logic;
    signal pixel_on_screen_position : screen_position_type;
    signal VGA_active : std_logic := '0';
    
    -- Keyboard
    signal keyboard_output : std_logic_vector(31 downto 0);

    signal COLOR_R, COLOR_G, COLOR_B: STD_LOGIC_VECTOR (7 downto 0);

    -- Component
    component keyboard_top
    port(
        CLK100MHZ : in std_logic;
        PS2_CLK : in std_logic;
        PS2_DATA : in std_logic;

        SEG : out std_logic_vector(6 downto 0);
        AN : out std_logic_vector(7 downto 0);
        out_keycode : out std_logic_vector(31 downto 0);
        DP : out std_logic;
        UART_TXD : out std_logic
    );
    end component;
    
    component clk_wiz_0
    port (
        reset : in std_logic;
        
        CLK_IN1  : in     std_logic;
        CLK_OUT1 : out    std_logic;
        CLK_OUT2 : out    std_logic
    );
    end component;
begin
    CLK_DIV : clk_wiz_0
    port map (
        reset => RST,
        
        CLK_IN1 => CLK100,
        CLK_OUT1 => CLK_VGA,
        CLK_OUT2 => CLK
    );
    
    -- I/O
    LED <= SW;

    I_KEYBOARD:keyboard_top
    port map (
        CLK100MHZ => CLK100,
        PS2_CLK => PS2_CLK,
        PS2_DATA => PS2_DATA,

        SEG => SEG,
        AN => AN,
        out_keycode => keyboard_output,

        DP => DP,
        UART_TXD => UART_TXD
    );

    I_GAME_CONTROLLER: entity work.game_controller
    generic map (
        SEED_LENGTH => NB_SWITCH,
        FREQUENCY   => FREQUENCY
    )
    port map (
        clk               => clk,
        rst               => rst,

        in_seed           => SW,

        in_io             => keyboard_output(7 downto 0),
        in_read_block     => in_read_block,

        game_end          => game_end,
        game_winner       => game_winner,

        out_grid_position => out_grid_position,
        out_block         => out_block,
        out_write         => out_write,

        out_players_position     => players_position,
        out_players_status       => players_status,
        out_players_alive        => players_alive
    );

    I_BLOCK_RAM: entity work.block_ram
    port map (
        clk    => clk,

        data_a => out_block,
        p_a    => out_grid_position,
        we_a   => out_write,
        q_a    => in_read_block,

        p_b    => out_request_pos,
        q_b    => in_block
    );
    
    -- Graphic controller
    I_GRAPHIC_CONTROLLER: entity work.graphic_controller
    port map (
        CLK                  => CLK,
        RST                  => RST,

        in_block             => in_block,
        out_request_pos      => out_request_pos,

        out_pixel_value      => out_pixel_value,
        out_pixel_position   => out_pixel_position,
        out_write_pixel      => write_pixel,

        in_players_position     => players_position,
        in_players_status       => players_status,
        in_players_alive        => players_alive
    );

    I_PIXEL_RAM: entity work.pixel_ram
    port map (
        a_clk  => CLK,
        a_wr   => write_pixel,
        a_pos => out_pixel_position,
        a_din  => out_pixel_value,

        b_clk  => CLK_VGA,
        b_pos => pixel_on_screen_position,
        b_dout => out_pixel
    );

    I_SPRITE_CONVERTER: entity work.sprite_converter
    port map (
        in_color    => out_pixel,
        out_color_R => COLOR_R,
        out_color_G => COLOR_G,
        out_color_B => COLOR_B
    );

    -- VGA Output
    VGA_R <= COLOR_R(7 downto 4) when VGA_active = '1' else x"0";
    VGA_G <= COLOR_G(7 downto 4) when VGA_active = '1' else x"0";
    VGA_B <= COLOR_B(7 downto 4) when VGA_active = '1' else x"0";

    I_VGA_CONTROLLER: entity work.vga_controller
    port map (
        CLK_I    => CLK_VGA,
        
        out_active => VGA_active,
        
        VGA_HS_O => VGA_HS_O,
        VGA_VS_O => VGA_VS_O,

        VGA_POSITION => pixel_on_screen_position
    );
end behavioral;
