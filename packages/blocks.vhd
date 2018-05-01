use work.PROJECT_TYPES_PKG.all;

package PROJECT_BLOCKS_PKG is
    constant EMPTY_BLOCK : block_category_type := 0;

    constant UNBREAKABLE_BLOCK_0 : block_category_type := 1;
    constant UNBREAKABLE_BLOCK_1 : block_category_type := 2;
    constant UNBREAKABLE_BLOCK_2 : block_category_type := 3;

    constant BREAKABLE_BLOCK_0 : block_category_type := 4;
    constant BREAKABLE_BLOCK_1 : block_category_type := 5;
    constant BREAKABLE_BLOCK_2 : block_category_type := 6;

    constant BOMB_BLOCK_0 : block_category_type := 7;
    constant BOMB_BLOCK_1 : block_category_type := 8;
    constant BOMB_BLOCK_2 : block_category_type := 9;

    constant EXPLOSION_BLOCK_JUNCTION : block_category_type := 10;
    constant EXPLOSION_BLOCK_MIDDLE : block_category_type := 11;
    constant EXPLOSION_BLOCK_END : block_category_type := 12;

    constant BONUS_LIFE_BLOCK : block_category_type := 13;
    constant BONUS_GODMODE_BLOCK : block_category_type := 14;
    constant BONUS_WALLHACK_BLOCK : block_category_type := 15;
    constant BONUS_MINIMIZE_PLAYER_BLOCK : block_category_type := 16;
    constant BONUS_SPEED_BLOCK : block_category_type := 17;
    constant BONUS_ADDBOMB_BLOCK : block_category_type := 18;
    constant BONUS_ADD_POWER_BLOCK : block_category_type := 19;

    constant MALUS_INVERSED_COMMANDS_BLOCK : block_category_type := 20;
    constant MALUS_DISABLE_BOMBS_BLOCK : block_category_type := 21;
    constant MALUS_MAXIMIZE_BLOCK : block_category_type := 22;
end package;
