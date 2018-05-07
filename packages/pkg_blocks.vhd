use work.PROJECT_TYPES_PKG.all;

package PROJECT_BLOCKS_PKG is
    constant EMPTY_BLOCK : block_category_type := 0;

    constant UNBREAKABLE_BLOCK_1 : block_category_type := 1;
    constant UNBREAKABLE_BLOCK_2 : block_category_type := 2;

    constant BREAKABLE_BLOCK_0 : block_category_type := 3;

    constant BOMB_BLOCK_0 : block_category_type := 4;

    constant EXPLOSION_BLOCK_JUNCTION : block_category_type := 5;
    constant EXPLOSION_BLOCK_MIDDLE : block_category_type := 6;
    constant EXPLOSION_BLOCK_END : block_category_type := 7;

    constant BONUS_LIFE_BLOCK : block_category_type := 8;
    constant BONUS_GODMODE_BLOCK : block_category_type := 9;
    constant BONUS_WALLHACK_BLOCK : block_category_type := 10;
    constant BONUS_SPEED_BLOCK : block_category_type := 11;
    constant BONUS_ADD_BOMB_BLOCK : block_category_type := 12;
    constant BONUS_ADD_POWER_BLOCK : block_category_type := 13;

    constant MALUS_INVERSED_COMMANDS_BLOCK : block_category_type := 14;
    constant MALUS_DISABLE_BOMBS_BLOCK : block_category_type := 15;
    constant MALUS_REMOVE_POWER_BLOCK : block_category_type := 16;
end package;
