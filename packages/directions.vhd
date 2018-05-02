package PROJECT_DIRECTION_PKG is
    constant D_UP : integer range 0 to 3 := 0;
    constant D_RIGHT : integer range 0 to 3 := 1;
    constant D_DOWN : integer range 0 to 3 := 2;
    constant D_LEFT : integer range 0 to 3 := 3;

    subtype direction_type is (D_UP, D_RIGHT, D_DOWN, D_LEFT);
end package;
