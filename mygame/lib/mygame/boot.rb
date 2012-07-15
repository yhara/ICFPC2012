require 'mygame'
require 'mygame/scene'
include MyGame
create_screen

END {
  unless $! or MyGame.ran_main_loop?
    MyGame.main_loop
  end
}
