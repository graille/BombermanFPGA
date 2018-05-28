library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_BLOCKS_PKG.all;

entity GAME_TOP is
    generic (
        FREQUENCY: integer := 100000000;
        NB_SWITCH : integer := 16
    );
    port (
        -- Basic inputs
        CLK100, RST : in std_logic := '0';

        -- Switches (to configure seeds for PRNG)
        SW : in std_logic_vector(NB_SWITCH - 1 downto 0) := (others => '0');

        -- LEDS
        LED : out std_logic_vector(NB_SWITCH - 1 downto 0) := (others => '0');

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
    signal gc_in_block             : block_type := DEFAULT_BLOCK;
    signal gc_out_request_pos      : grid_position := DEFAULT_GRID_POSITION;
    signal gc_out_pixel_value      : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0) := (others => '0');
    signal gc_out_pixel_position   : screen_position_type := DEFAULT_SCREEN_POSITION;

    signal gc_in_player_position     : vector := DEFAULT_VECTOR_POSITION;
    signal gc_in_player_status       : player_status_type := DEFAULT_PLAYER_STATUS;

    signal gc_out_request_player      : integer range 0 to NB_PLAYERS - 1 := 0;

    signal gc_out_write_pixel : std_logic := '0';

    -- Game controller
    signal gu_in_read_block     : block_type := DEFAULT_BLOCK;

    signal gu_out_game_end          : std_logic := '0';
    signal gu_out_game_winner       : integer range 0 to NB_PLAYERS - 1;

    signal gu_out_grid_position : grid_position := DEFAULT_GRID_POSITION;
    signal gu_out_block         : block_type := DEFAULT_BLOCK;
    signal gu_out_write         : std_logic := '0';

    -- Pixel ram
    signal pr_out_pixel : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

    -- Sprite converter
    signal in_color    : std_logic_vector(4 downto 0);

    -- VGA Controller
    signal CLK_VGA    : std_logic;
    signal pixel_on_screen_position : screen_position_type;
    signal VGA_active : std_logic := '0';

    signal VGA_HS_O_t : STD_LOGIC;
    signal VGA_VS_O_t : STD_LOGIC;

    -- I/O
    signal keyboard_output : std_logic_vector(31 downto 0);
    signal next_io : io_signal;


    signal CLK_KEYBOARD : std_logic;
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
        CLK_IN1  : in     std_logic;
        CLK_OUT1 : out    std_logic;
        CLK_OUT2 : out    std_logic;
        CLK_OUT3 : out    std_logic
    );
    end component;
begin
--    LED_DEBUG:for K in 0 to (NB_PLAYERS - 1) mod 4 generate
--        LED(K * 4) <= '1' when keyboard_output(7 downto 0) = CONTROL_SET_FORWARD(K) else '0';
--        LED(K * 4 + 1) <= '1' when keyboard_output(7 downto 0) = CONTROL_SET_LEFT(K) else '0';
--        LED(K * 4 + 2) <= '1' when keyboard_output(7 downto 0) = CONTROL_SET_BACK(K) else '0';
--        LED(K * 4 + 3) <= '1' when keyboard_output(7 downto 0) = CONTROL_SET_RIGHT(K) else '0';
--    end generate;

    CLK_DIV : clk_wiz_0
    port map (
        CLK_IN1 => CLK100,

        CLK_OUT1 => CLK,
        CLK_OUT2 => CLK_VGA,
        CLK_OUT3 => CLK_KEYBOARD
    );

    -- I/O
    LED <= SW;

    I_IO_CONTROLLER : entity work.io_controller
    generic map (
        FREQUENCY => FREQUENCY
    )
    port map (
        CLK => CLK,
        RST         => RST,

        in_command  => keyboard_output(15 downto 0),
        out_command => next_io
    );

    I_KEYBOARD:keyboard_top
    port map (
        CLK100MHZ => CLK_KEYBOARD,
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

        in_io             => next_io,
        in_read_block     => gu_in_read_block,

        game_end          => gu_out_game_end,
        game_winner       => gu_out_game_winner,

        out_grid_position => gu_out_grid_position,
        out_block         => gu_out_block,
        out_write         => gu_out_write,

        in_requested_player     => gc_out_request_player,
        out_player_position     => gc_in_player_position,
        out_player_status       => gc_in_player_status
    );

    I_BLOCK_RAM: entity work.block_ram
    port map (
        clk    => clk,

        data_a => gu_out_block,
        p_a    => gu_out_grid_position,
        we_a   => gu_out_write,
        q_a    => gu_in_read_block,

        p_b    => gc_out_request_pos,
        q_b    => gc_in_block
    );

    -- Graphic controller
    I_GRAPHIC_CONTROLLER: entity work.graphic_controller
    port map (
        CLK                  => CLK,
        RST                  => RST,

        in_block             => gc_in_block,
        out_request_pos      => gc_out_request_pos,

        out_pixel_value      => gc_out_pixel_value,
        out_pixel_position   => gc_out_pixel_position,
        out_write_pixel      => gc_out_write_pixel,

        out_request_player     => gc_out_request_player,
        in_player_position     => gc_in_player_position,
        in_player_status       => gc_in_player_status,

        in_new_image        => VGA_VS_O_t
    );

    I_PIXEL_RAM: entity work.pixel_ram
    port map (
        a_clk  => CLK,
        a_wr   => gc_out_write_pixel,
        a_pos  => gc_out_pixel_position,
        a_din  => gc_out_pixel_value,

        b_clk  => CLK_VGA,
        b_pos  => pixel_on_screen_position,
        b_dout => pr_out_pixel
    );

    I_SPRITE_CONVERTER: entity work.sprite_converter
    port map (
        in_color    => pr_out_pixel,
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
        pxl_clk    => CLK_VGA,

        out_active => VGA_active,

        VGA_HS_O => VGA_HS_O_t,
        VGA_VS_O => VGA_VS_O_t,

        VGA_POSITION => pixel_on_screen_position
    );
    VGA_HS_O <= VGA_HS_O_t;
    VGA_VS_O <= VGA_VS_O_t;
end behavioral;
