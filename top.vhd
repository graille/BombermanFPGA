library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_RECT_PKG.all;

entity top is 
    generic (
        FREQUENCY: integer := 100000000;
        
        GAME_ROWS : integer := 12;
        GAME_COLS : integer := 16
    );
    port (
        -- Basic inputs
        CLK, RST : in std_logic;
        
        -- VGA Outputs
        VGA_HS_O : out  STD_LOGIC;
        VGA_VS_O : out  STD_LOGIC;
        VGA_R : out  STD_LOGIC_VECTOR (3 downto 0);
        VGA_B : out  STD_LOGIC_VECTOR (3 downto 0);
        VGA_G : out  STD_LOGIC_VECTOR (3 downto 0)
    );
end top;

architecture behavioural of top is

-- Signals
signal current_pixel : pixel;
signal current_block : block_type; 

component graphic_controller is
    port(
        CLK, RST : in std_logic
    );
end component;

component game_controller is
    generic(
        ROWS : integer;
        COLS : integer;
        FREQUENCY : integer;
        NB_PLAYERS : integer
    );
    port(
        CLK, RST : in std_logic;
    
        game_end : out std_logic := '0';
        game_winner : out integer range 0 to NB_PLAYERS - 1
    );
end component;

begin
    GAME_CONTROLLER_GENERATED:game_controller
    generic map (
        ROWS => GAME_ROWS,
        COLS => GAME_COLS,
        FREQUENCY => FREQUENCY,
        NB_PLAYERS => 1
    )
    port map (
        CLK => CLK,
        RST => RST
    );
    
    GAME_INFO_FOR_GRAPHIC_RAM:entity work.block_ram
    generic map (
        ROWS => GAME_ROWS,
        COLS => GAME_COLS
    )
    port map (
        -- Port A
        clk  => CLK,
        we_a   => '0',
        i_a => 0,
        j_a => 0,
        data_a  => (0,0,0),
         
        -- Port B
        i_b => 0,
        j_b => 0,
        q_b => current_block
    );
    
    
    GRAPHIC_CONTROLLER_GENERATED:graphic_controller
    port map (
        CLK => CLK,
        RST => RST
    );
    
    -- Graphic drivers
    PIXEL_RAM:entity work.pixel_ram
    generic map (
        WIDTH    => 800,
        HEIGHT   => 600
    )
    port map (
        -- Port A
        a_clk  => CLK,
        a_wr   => '0',
        a_addr => 0,
        a_din  => ((others=>'0'),(others=>'0'),(others=>'0')),
        
        -- Port B
        b_clk  => CLK,
        b_addr => 0,
        b_dout => current_pixel
    );
    
    VGA_DRIVER:entity work.VGA_CONTROLLER
    port map ( 
        CLK_I => CLK,
        VGA_HS_O  => VGA_HS_O,
        VGA_VS_O => VGA_VS_O,
        VGA_R => VGA_R,
        VGA_B => VGA_B,
        VGA_G => VGA_G
    );
end behavioural;