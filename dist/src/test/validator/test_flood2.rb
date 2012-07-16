# -*- coding: utf-8 -*-

=begin
generated at 2012-07-16T14:50:58+09:00

#######
#..***#
#..\\\#
#...**#
#.*.*\#
LR....#
#######

Flooding 5
Waterproof 3

|
| RRUDRRULURULLLLDDDL
v

#######
#..   #
#  *  #
# ..  #
#   **#
O ****#
#######
=end

class LambdaLifter
  class TestFlood2 < Test::Unit::TestCase
    should "Validatorと同じ結果になる" do
      pend
      mine = Mine.new(<<EOS)
#######
#..***#
#..\\\#
#...**#
#.*.*\#
LR....#
#######

Flooding 5
Waterproof 3
EOS
      "RRUDRRULURULLLLDDDL".each_char do |s|
        mine.step!(s)
      end
      assert_equal <<EOS, mine.ascii_map
#######
#..   #
#  *  #
# ..  #
#   **#
O ****#
#######
EOS
      assert_equal 281, mine.score
    end
  end
end
