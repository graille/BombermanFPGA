library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PROJECT_TYPES_PKG.all;
use work.PROJECT_RECT_PKG.all;

entity top is 
    generic (
        FREQUENCY: integer := 100000000
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
        ROWS => 12,
        COLS => 16,
        FREQUENCY => FREQUENCY,
        NB_PLAYERS => 1
    )
    port map (
        CLK => CLK,
        RST => RST
    );
    
    GRAPHIC_CONTROLLER_GENERATED:graphic_controller
    port map (
        CLK => CLK,
        RST => RST
    );
    
    -- Graphic drivers    
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