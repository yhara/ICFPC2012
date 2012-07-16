# -*- coding: utf-8 -*-

=begin
This file is generated by mktest command.
generated at 2012-07-16T16:37:40+09:00

#########
#.*..#\.#
#.\..#\.L
#.R .##.#
#.\  ...#
#..\  ..#
#...\  ##
#....\ \#
#########

|
| URRDDRDRDDLRRLUUULLUUULLDDDRDRDA
v

#########
#.   #\.#
#.   #\.L
#.   ##.#
#.     .#
#..    .#
#...R  ##
#....*  #
#########
score: 269
=end

class LambdaLifter
  class TestContest4 < Test::Unit::TestCase
    should "Validatorと同じ結果になる" do
      commands = "URRDDRDRDDLRRLUUULLUUULLDDDRDRDA"
      score = 269
      map = <<'EOS'
#########
#.*..#\.#
#.\..#\.L
#.R .##.#
#.\  ...#
#..\  ..#
#...\  ##
#....\ \#
#########
EOS
      processed_map = <<'EOS'
#########
#.   #\.#
#.   #\.L
#.   ##.#
#.     .#
#..    .#
#...R  ##
#....*  #
#########
EOS

      mine = Mine.new(map)
      commands.each_char do |s|
        mine.step!(s)
      end
      ascii_map = mine.validator_map
      # Validatorはクリア時にOだがMineはクリア時はRなのでその補正
      ascii_map = ascii_map.sub("R", "O") if !/O/.match(ascii_map)
      assert_equal processed_map, ascii_map, <<INPUT
#{map}

|
| #{commands}
v

#{processed_map}
score: #{score}
INPUT
      assert_equal score, mine.score
    end
  end
end
