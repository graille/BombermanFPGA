library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package PROJECT_TYPES_PKG is
  type array_unsigned is array(natural range <>) of unsigned;
  type array_signed is array(natural range <>) of signed;
  type array_stv is array(natural range <>) of std_logic_vector;
  type array_integer is array(natural range <>) of integer;
  type array_natural is array(natural range <>) of natural;

  type array_logic is array(natural range <>) of std_logic;

  type td_array_unsigned is array(natural range <>, natural range <>) of unsigned;
  type td_array_signed is array(natural range <>, natural range <>) of signed;
  type td_array_stv is array(natural range <>, natural range <>) of std_logic_vector;
  type td_array_integer is array(natural range <>, natural range <>) of integer;

  type td_array_logic is array(natural range <>, natural range <>) of std_logic;


  type td_array_cube_types is array(natural range <>, natural range <>) of integer range 0 to 2**4-1;
  type vector is array(2 downto 0) of unsigned(16 downto 0);
  subtype io_signal is std_logic_vector(7 downto 0);
end package;
