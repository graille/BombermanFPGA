TAB = "    "
NEWLINE = "\n"


def generate_converter(bits_precision, colors_list_hex, entity_name="sprite_converter"):
    l = []
    # Entity declaration
    l.append("library IEEE;")
    l.append("use IEEE.std_logic_1164.all;")
    l.append("use IEEE.numeric_std.all;")
    l.append("")

    l.append("entity " + entity_name + " is")

    #l.append(TAB + "generic (")
    #l.append(TAB * 2 + 'SPRITE_COLOR_PRECISION : integer := ' + str(bits_precision))
    #l.append(TAB + ");")

    l.append(TAB + "port (")
    l.append(TAB * 2 + 'in_color : std_logic_vector(' + str(bits_precision - 1) + ' downto 0);')
    l.append("")
    l.append(TAB * 2 + 'out_color_R : std_logic_vector(7 downto 0);')
    l.append(TAB * 2 + 'out_color_G : std_logic_vector(7 downto 0);')
    l.append(TAB * 2 + 'out_color_B : std_logic_vector(7 downto 0)')
    l.append(TAB + ");")

    l.append("end " + entity_name + ";")

    l.append("")

    # Architecture
    l.append("architecture behavioural of " + entity_name + " is")
    l.append(TAB + "signal in_color_n : integer range 0 to 2**" + str(bits_precision) + " - 1 := 0;")
    l.append("begin")

    l.append(TAB + "in_color_n <= to_integer(unsigned(in_color));")

    l.append("")
    l.append(TAB + "process(in_color_n)")
    l.append(TAB + "begin")

    l.append(TAB * 2 + "case in_color_n is")

    for i, elt in enumerate(colors_list_hex):
        l.append(TAB * 3 + "when " + str(i) + " =>")
        l.append(TAB * 4 + "out_color_R <= x\"" + elt[:2] + "\";")
        l.append(TAB * 4 + "out_color_G <= x\"" + elt[2:4] + "\";")
        l.append(TAB * 4 + "out_color_B <= x\"" + elt[4::] + "\";")

    l.append(TAB * 3 + "when others => null;")
    l.append(TAB * 2 + "end case;")

    l.append(TAB + "end process;")

    l.append("end behavioural;")

    with open(entity_name + ".vhd", 'w', encoding='utf-8') as f:
        for line in l:
            f.write(line + NEWLINE)


def generate_rom(bits_precision, colors_list_rgb, images_description, entity_name="sprite_rom"):
    l = []

    max_w = 0
    max_h = 0

    total_rows = 0

    # Entity declaration
    l.append("library IEEE;")
    l.append("use IEEE.std_logic_1164.all;")
    l.append("use IEEE.numeric_std.all;")
    l.append("")

    l.append("entity " + entity_name + " is")

    l.append(TAB + "port (")
    l.append(TAB * 2 + 'clk : std_logic;')
    l.append(TAB * 2 + 'in_sprite_nb : integer range 0 to ' + str(len(images_description) - 1) + ';')
    l.append(TAB * 2 + 'in_sprite_row : integer range 0 to ' + str(max_h - 1) + ';')
    l.append(TAB * 2 + 'in_sprite_col : integer range 0 to ' + str(max_w - 1) + ';')
    l.append("")
    l.append(TAB * 2 + 'out_color : std_logic_vector(' + str(bits_precision - 1) + ' downto 0)')
    l.append(TAB + ");")

    l.append("end " + entity_name + ";")

    l.append("")

    # Architecture
    l.append("architecture behavioural of " + entity_name + " is")
    l.append(TAB + "subtype word_t is std_logic_vector(" + str(bits_precision - 1) + " downto 0);")
    l.append(TAB + "type memory_t is array(" + str(total_rows - 1) + " downto 0, " + str(max_w - 1) + " downto 0) of word_t;")
    l.append("begin")

    l.append("")
    l.append(TAB + "process(clk)")
    l.append(TAB*2 + 'variable real_row : integer range 0 to ' + str(total_rows - 1) + ';')
    l.append(TAB + "begin")

    cumulative_rows = 0
    l.append(TAB * 2 + "case in_sprite_nb is")
    for i, desc in enumerate(images_description):
        l.append(TAB * 3 + "when " + str(i) + " =>")
        l.append(TAB*4 + "real_row <= " + str(cumulative_rows) + " + in_sprite_row")

        cumulative_rows += len(desc)

    l.append(TAB * 3 + "when others => null;")
    l.append(TAB * 2 + "end case;")

    l.append(TAB * 2 + "if rising_edge(clk) then")
    l.append(TAB * 3 + "out_color <= rom(real_row, in_sprite_col);")
    l.append(TAB * 2 + "end if;")

    l.append(TAB + "end process;")

    l.append("end behavioural;")

    with open(entity_name + ".vhd", 'w', encoding='utf-8') as f:
        for line in l:
            f.write(line + NEWLINE)
