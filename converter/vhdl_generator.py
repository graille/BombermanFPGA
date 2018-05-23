TAB = "    "
NEWLINE = "\n"


def generate_converter(bits_precision, colors_list_hex, entity_name="sprite_converter"):
    l = []
    # Entity declaration
    l += ["library IEEE;"]
    l += ["use IEEE.std_logic_1164.all;"]
    l += ["use IEEE.numeric_std.all;"]
    l += [""]

    l += ["entity " + entity_name + " is"]

    l += [TAB + "port ("]
    l += [TAB * 2 + 'in_color : in std_logic_vector(' + str(bits_precision - 1) + ' downto 0);']
    l += [""]
    l += [TAB * 2 + 'out_color_R : out std_logic_vector(7 downto 0);']
    l += [TAB * 2 + 'out_color_G : out std_logic_vector(7 downto 0);']
    l += [TAB * 2 + 'out_color_B : out std_logic_vector(7 downto 0)']
    l += [TAB + ");"]

    l += ["end " + entity_name + ";"]

    l += [""]

    # Architecture
    l += ["architecture behavioral of " + entity_name + " is"]
    l += [TAB + "signal in_color_n : integer range 0 to 2**" + str(bits_precision) + " - 1 := 0;"]
    l += ["begin"]

    l += [TAB + "in_color_n <= to_integer(unsigned(in_color));"]

    l += [""]
    l += [TAB + "process(in_color_n)"]
    l += [TAB + "begin"]

    l += [TAB * 2 + "case in_color_n is"]

    for i, elt in enumerate(colors_list_hex):
        l += [TAB * 3 + "when " + str(i) + " =>"]
        l += [TAB * 4 + "out_color_R <= x\"" + elt[:2] + "\";"]
        l += [TAB * 4 + "out_color_G <= x\"" + elt[2:4] + "\";"]
        l += [TAB * 4 + "out_color_B <= x\"" + elt[4::] + "\";"]

    l += [TAB * 3 + "when others => null;"]
    l += [TAB * 2 + "end case;"]

    l += [TAB + "end process;"]

    l += ["end behavioral;"]

    with open(entity_name + ".vhd", 'w', encoding='utf-8') as f:
        for line in l:
            f.write(line + NEWLINE)


def generate_rom(bits_precision, colors_list, images_description, images_names, entity_name="sprite_rom"):
    l = []

    images_names = list(map(lambda s : (s.split("."))[0], images_names))
    assets_repartition = {}

    for i, name in enumerate(images_names):
        image_splitted_name = name.split("_")
        image_id = int(image_splitted_name[0])

        if image_id not in assets_repartition.keys():
            assets_repartition[image_id] = {}

        if len(image_splitted_name) >= 3:
            n_state = int(image_splitted_name[2])

            if n_state not in list((assets_repartition[image_id]).keys()):
                assets_repartition[image_id][n_state] = {}

            if len(image_splitted_name) >= 4:
                orientation = int(image_splitted_name[3])
                assets_repartition[image_id][n_state][orientation] = images_description[i]
            else:
                assets_repartition[image_id][n_state] = images_description[i]
        else:
             assets_repartition[image_id] = images_description[i]

    max_w = max(map(lambda x: len(x[0]), images_description))
    max_h = max(map(len, images_description))

    total_rows = sum(map(len, images_description))

    # Entity declaration
    l += ["library IEEE;"]
    l += ["use IEEE.std_logic_1164.all;"]
    l += ["use IEEE.numeric_std.all;"]
    l += [""]

    l += ["use work.PROJECT_PARAMS_PKG.all;"]
    l += ["use work.PROJECT_TYPES_PKG.all;"]
    l += ["use work.PROJECT_DIRECTION_PKG.all;"]
    l += [""]

    l += ["entity " + entity_name + " is"]

    l += [TAB + "port ("]
    l += [TAB * 2 + 'clk : in std_logic;']

    l += [""]

    l += [TAB * 2 + 'in_sprite_id : in block_category_type;']
    l += [TAB * 2 + 'in_sprite_state : in state_type;']
    l += [TAB * 2 + 'in_sprite_direction : in direction_type;']
    l += [""]

    l += [TAB * 2 + 'in_sprite_row : in integer range 0 to ' + str(max_h - 1) + ';']
    l += [TAB * 2 + 'in_sprite_col : in integer range 0 to ' + str(max_w - 1) + ';']
    l += [""]
    l += [TAB * 2 + 'out_color : out std_logic_vector(' + str(bits_precision - 1) + ' downto 0) := (others => \'0\')']
    l += [TAB + ");"]

    l += ["end " + entity_name + ";"]

    l += [""]

    # Architecture
    l += ["architecture behavioral of " + entity_name + " is"]
    l += [TAB + "subtype word_t is std_logic_vector(" + str(max_w*bits_precision - 1) + " downto 0);"]
    l += [TAB + "type memory_t is array(" + str(total_rows - 1) + " downto 0) of word_t;"]

    l += [""]

    l += [TAB + "function init_mem "]

    l += [TAB * 2 + "return memory_t is"]
    l += [TAB * 2 + "begin"]

    l += [TAB * 3 + "return ("]

    for k, descriptor in enumerate(images_description):
        l += [TAB * 4 + "-- " + str(images_names[k])]

        for i, line in enumerate(descriptor):
            line_bits = ""
            f_string = "{0:0" + str(bits_precision) + "b}"

            for j, pixel in enumerate(line):
                line_bits += f_string.format(pixel)

            if len(line_bits) % 4 == 0:
                decimal_line = int(line_bits, 2)
                h_f_string = "{0:0" + str(int(len(line_bits) / 4)) + "x}"
                line_bits = h_f_string.format(decimal_line)
                line_bits = "x\"" + line_bits + "\""
            else:
                line_bits = "\"" + line_bits + "\""

            line_str = "(" + line_bits + ")"

            if (k != len(images_description) - 1) or (i != len(descriptor) - 1):
                line_str += ","

            l += [TAB * 4 + line_str]

        if k != len(images_description) - 1:
            l += [""]

    l += [TAB * 3 + ");"]

    l += [TAB + "end init_mem;"]

    l += [""]

    l += [TAB + "constant rom : memory_t := init_mem;"]
    l += [TAB + 'signal real_row : integer range 0 to ' + str(total_rows - 1) + ' := 0;']
    l += [TAB + 'signal out_color_reg : std_logic_vector(' + str(max_w*bits_precision - 1) + ' downto 0) := (others => \'0\');']

    l += ["begin"]

    l += [TAB + "process(in_sprite_id, in_sprite_row, in_sprite_col)"]
    l += [TAB + "begin"]

    cumulative_rows = 0
    l += [TAB * 2 + "case in_sprite_id is"]
    for i in sorted(list(assets_repartition.keys())):
        assets = assets_repartition[i]
        l += [TAB * 3 + "when " + str(i) + " =>"]

        if isinstance(assets, dict):
            l += [TAB * 4 + "case in_sprite_state is"]

            for state in sorted(list(assets.keys())):
                l += [TAB * 5 + "when " + str(state) + " =>"]

                if isinstance(assets[state], dict):
                    l += [TAB * 6 + "case in_sprite_direction is"]

                    for direction in sorted(list(assets[state].keys())):
                        direction = int(direction)

                        direction_a = direction
                        direction_a = "D_UP" if direction == 0 else direction_a
                        direction_a = "D_LEFT" if direction == 1 else direction_a
                        direction_a = "D_DOWN" if direction == 2 else direction_a
                        direction_a = "D_RIGHT" if direction == 3 else direction_a

                        l += [TAB * 7 + "when " + str(direction_a) + " =>"]

                        if cumulative_rows != 0:
                            l[-1] += " real_row <= " + str(cumulative_rows) + " + in_sprite_row;"
                        else:
                            l[-1] += " real_row <= in_sprite_row;"

                        cumulative_rows += len(assets[state][direction])

                    l += [TAB * 7 + "when others => null;"]
                    l += [TAB * 6 + "end case;"]
                else:
                    if cumulative_rows != 0:
                        l[-1] += " real_row <= " + str(cumulative_rows) + " + in_sprite_row;"
                    else:
                        l[-1] += " real_row <= in_sprite_row;"

                    cumulative_rows += len(assets[state])

            l += [TAB * 5 + "when others => null;"]
            l += [TAB * 4 + "end case;"]
        else:
            if cumulative_rows != 0:
                l[-1] += " real_row <= " + str(cumulative_rows) + " + in_sprite_row;"
            else:
                l[-1] += " real_row <= in_sprite_row;"

            cumulative_rows += len(assets)

    l += [TAB * 3 + "when others => null;"]
    l += [TAB * 2 + "end case;"]
    l += [TAB + "end process;"]

    l += [""]

    l += [TAB + "process(clk)"]
    l += [TAB + "begin"]

    l += [TAB * 2 + "if rising_edge(clk) then"]
    l += [TAB * 3 + "out_color_reg <= rom(real_row);"]
    l += [TAB * 2 + "end if;"]

    l += [TAB + "end process;"]

    l += [TAB + "out_color <= out_color_reg(((in_sprite_col + 1) * " + str(bits_precision) + ") - 1 downto (in_sprite_col * " + str(bits_precision) + "));"]

    l += ["end behavioral;"]

    with open(entity_name + ".vhd", 'w', encoding='utf-8') as f:
        for line in l:
            f.write(line + NEWLINE)
