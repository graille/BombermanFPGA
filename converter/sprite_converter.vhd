library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sprite_converter is
    port (
        in_color : in std_logic_vector(4 downto 0);

        out_color_R : out std_logic_vector(7 downto 0);
        out_color_G : out std_logic_vector(7 downto 0);
        out_color_B : out std_logic_vector(7 downto 0)
    );
end sprite_converter;

architecture behavioral of sprite_converter is
    signal in_color_n : integer range 0 to 2**5 := 0;
begin
    in_color_n <= to_integer(unsigned(in_color));

    process(in_color_n)
    begin
        case in_color_n is
            when 0 =>
                out_color_R <= x"00";
                out_color_G <= x"00";
                out_color_B <= x"00";
            when 1 =>
                out_color_R <= x"FF";
                out_color_G <= x"FF";
                out_color_B <= x"FF";
            when 2 =>
                out_color_R <= x"34";
                out_color_G <= x"32";
                out_color_B <= x"37";
            when 3 =>
                out_color_R <= x"8B";
                out_color_G <= x"88";
                out_color_B <= x"7C";
            when 4 =>
                out_color_R <= x"D5";
                out_color_G <= x"DD";
                out_color_B <= x"E6";
            when 5 =>
                out_color_R <= x"93";
                out_color_G <= x"9B";
                out_color_B <= x"A3";
            when 6 =>
                out_color_R <= x"2D";
                out_color_G <= x"35";
                out_color_B <= x"43";
            when 7 =>
                out_color_R <= x"3C";
                out_color_G <= x"4C";
                out_color_B <= x"5A";
            when 8 =>
                out_color_R <= x"F7";
                out_color_G <= x"C5";
                out_color_B <= x"35";
            when 9 =>
                out_color_R <= x"F7";
                out_color_G <= x"75";
                out_color_B <= x"25";
            when 10 =>
                out_color_R <= x"00";
                out_color_G <= x"66";
                out_color_B <= x"F3";
            when 11 =>
                out_color_R <= x"8F";
                out_color_G <= x"B8";
                out_color_B <= x"ED";
            when 12 =>
                out_color_R <= x"6F";
                out_color_G <= x"1D";
                out_color_B <= x"0D";
            when 13 =>
                out_color_R <= x"38";
                out_color_G <= x"9E";
                out_color_B <= x"5D";
            when 14 =>
                out_color_R <= x"34";
                out_color_G <= x"51";
                out_color_B <= x"43";
            when 15 =>
                out_color_R <= x"51";
                out_color_G <= x"68";
                out_color_B <= x"76";
            when 16 =>
                out_color_R <= x"68";
                out_color_G <= x"87";
                out_color_B <= x"9D";
            when 17 =>
                out_color_R <= x"0B";
                out_color_G <= x"7E";
                out_color_B <= x"C9";
            when 18 =>
                out_color_R <= x"19";
                out_color_G <= x"BD";
                out_color_B <= x"E3";
            when 19 =>
                out_color_R <= x"F6";
                out_color_G <= x"29";
                out_color_B <= x"1B";
            when 20 =>
                out_color_R <= x"2C";
                out_color_G <= x"17";
                out_color_B <= x"18";
            when 21 =>
                out_color_R <= x"F7";
                out_color_G <= x"C3";
                out_color_B <= x"42";
            when 22 =>
                out_color_R <= x"F7";
                out_color_G <= x"23";
                out_color_B <= x"35";
            when 23 =>
                out_color_R <= x"F8";
                out_color_G <= x"E0";
                out_color_B <= x"A1";
            when 24 =>
                out_color_R <= x"F6";
                out_color_G <= x"6E";
                out_color_B <= x"25";
            when 25 =>
                out_color_R <= x"9C";
                out_color_G <= x"00";
                out_color_B <= x"10";
            when 26 =>
                out_color_R <= x"F6";
                out_color_G <= x"5C";
                out_color_B <= x"23";
            when 27 =>
                out_color_R <= x"F8";
                out_color_G <= x"CC";
                out_color_B <= x"46";
            when 28 =>
                out_color_R <= x"12";
                out_color_G <= x"2D";
                out_color_B <= x"13";
            when 29 =>
                out_color_R <= x"34";
                out_color_G <= x"34";
                out_color_B <= x"34";
            when 30 =>
                out_color_R <= x"3C";
                out_color_G <= x"44";
                out_color_B <= x"44";
            when 31 =>
                out_color_R <= x"0D";
                out_color_G <= x"54";
                out_color_B <= x"3D";
            when others => null;
        end case;
    end process;
end behavioral;
