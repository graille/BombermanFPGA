library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.PROJECT_PARAMS_PKG.all;
use work.PROJECT_TYPES_PKG.all;

entity top is
    generic (
        FREQUENCY: integer := 100000000;
        SEED_LENGTH : integer := 16
    );
    port (
        -- Basic inputs
        CLK, RST : in std_logic;

        -- Switches (to configure seeds for PRNG)
        SW : in std_logic_vector(SEED_LENGTH - 1 downto 0);

        -- VGA Outputs
        VGA_HS_O : out  STD_LOGIC;
        VGA_VS_O : out  STD_LOGIC;
        VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
        VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
        VGA_G : out  STD_LOGIC_VECTOR (3 downto 0);
        
        -- Keyboard inputs
        KEYBOARD_DATA : in std_logic;
        
        SEG : out std_logic_vector(6 downto 0);
        AN : out std_logic_vector(7 downto 0);
        DP : out std_logic;
        UART_TXD : out std_logic
    );
end top;

architecture behavioral of top is
    -- Signals
  signal current_block : block_type;

  -- Graphic controller
  signal in_block             : block_type;
  signal in_players_positions : array_vector(NB_PLAYERS - 1 downto 0);
  signal out_request_pos      : grid_position;
  signal out_pixel_value      : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
  signal out_pixel_position   : screen_position_type;
  signal players_position     : array_vector(NB_PLAYERS - 1 downto 0);
  signal players_status       : array_player_status_type(NB_PLAYERS - 1 downto 0);
  signal players_alive        : std_logic_vector(NB_PLAYERS - 1 downto 0);

  -- Game controller
  signal in_io             : io_signal;
  signal in_read_block     : block_type;
  signal game_end          : std_logic := '0';
  signal game_winner       : integer range 0 to NB_PLAYERS - 1;
  signal out_grid_position : grid_position;
  signal out_block         : block_type;
  signal out_write         : std_logic;

  -- Pixel ram
  signal a_wr   : std_logic;
  signal a_addr : natural range 0 to (FRAME_WIDTH * FRAME_HEIGHT) - 1;
  signal a_din  : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
  signal a_dout : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);
  signal b_clk  : std_logic;
  signal b_addr : natural range 0 to (FRAME_WIDTH * FRAME_HEIGHT) - 1;
  signal b_dout : std_logic_vector(COLOR_BIT_PRECISION - 1 downto 0);

  -- Block RAM
  signal data_a   : block_type;
  signal p_a, p_b : grid_position;
  signal we_a     : std_logic := '0';
  signal q_a      : block_type;
  signal q_b      : block_type;

  -- Sprite converter
  signal in_color    : std_logic_vector(4 downto 0);
  signal out_color_R : std_logic_vector(7 downto 0);
  signal out_color_G : std_logic_vector(7 downto 0);
  signal out_color_B : std_logic_vector(7 downto 0);

  -- VGA Controller
  signal clk_pxl    : STD_LOGIC;
  
  -- Keyboard
  signal ps2_clk : std_logic;
  signal keyboard_output : std_logic_vector(31 downto 0);
begin
    I_GRAPHIC_CONTROLLER: entity work.graphic_controller
    port map (
        CLK                  => CLK,
        RST                  => RST,
        
        in_block             => in_block,
        in_players_positions => in_players_positions,
        
        out_request_pos      => out_request_pos,
        out_pixel_value      => out_pixel_value,
        out_pixel_position   => out_pixel_position,
        in_players_position     => players_position,
        in_players_status       => players_status,
        in_players_alive        => players_alive
    );

    I_GAME_CONTROLLER: entity work.game_controller
    generic map (
        SEED_LENGTH => SEED_LENGTH,
        FREQUENCY   => FREQUENCY
    )
    port map (
        clk               => clk,
        rst               => rst,
        in_seed           => SW,
        in_io             => in_io,
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

    I_PIXEL_RAM: entity work.pixel_ram
    port map (
        a_clk  => clk,
        a_wr   => a_wr,
        a_addr => a_addr,
        a_din  => a_din,
        a_dout => a_dout,
        
        b_clk  => clk_pxl,
        b_addr => b_addr,
        b_dout => b_dout
    );
      
    I_KEYBOARD: entity work.keyboard_top
    port map (
        CLK100MHZ => clk,
        PS2_CLK => ps2_clk,
        PS2_DATA => KEYBOARD_DATA,
        
        SEG => SEG,
        AN => AN,
        out_keycode => keyboard_output,
        
        DP => DP,
        UART_TXD => UART_TXD
    );
    in_io <= keyboard_output(7 downto 0);

    I_BLOCK_RAM: entity work.block_ram
    port map (
        clk    => clk,
        data_a => data_a,
        
        p_a    => p_a,
        p_b    => p_b,
        we_a   => we_a,
        
        q_a    => q_a,
        q_b    => q_b
    );

    in_color <= b_dout;
    
    I_SPRITE_CONVERTER: entity work.sprite_converter
    port map (
        in_color    => in_color,
        out_color_R => out_color_R,
        out_color_G => out_color_G,
        out_color_B => out_color_B
    );

    I_VGA_CONTROLLER: entity work.VGA_CONTROLLER
    port map (
        CLK_I    => clk,
        CLK_O    => clk_pxl,
        VGA_HS_O => VGA_HS_O,
        VGA_VS_O => VGA_VS_O
    );
end behavioral;
