# -*- coding: utf-8 -*-

=begin
This file is generated by mktest command.
generated at 2012-07-16T18:57:32+09:00

#########
#.*..#\.#
#.\..#\.L
#.R .##.#
#.\  ...#
#..\  ..#
#...\  ##
#....\ \#
#########

Water 2
Flooding 11
Waterproof 5

|
| ULDRDDRA
v

#########
#. ..#\.#
#  ..#\.L
#   .##.#
#.   ...#
#. R  ..#
#...\  ##
#....\*\#
#########
score: 143
=end

require_relative "validator_test"

class LambdaLifter
  class TestFlood5 < ValidatorTest
    should "Validatorと同じ結果になる" do
      commands = "ULDRDDRA"
      score = 143
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

Water 2
Flooding 11
Waterproof 5
EOS
      processed_map = <<'EOS'
#########
#. ..#\.#
#  ..#\.L
#   .##.#
#.   ...#
#. R  ..#
#...\  ##
#....\*\#
#########
EOS

      mine = Mine.new(map)
      commands.each_char do |s|
        mine.step!(s)
      end
      assert_equal treat_expected_map(processed_map),
        treat_actual_map(mine.validator_map), <<INPUT
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
