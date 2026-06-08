enum Player { one, two }

Player other(Player p) => p == Player.one ? Player.two : Player.one;
