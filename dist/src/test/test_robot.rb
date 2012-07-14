# coding: utf-8

class LambdaLifter
  class TestRobot < Test::Unit::TestCase
    should ".x, .yでアクセスできること" do
      robot = LambdaLifter::Robot.new(nil, 1, 1)
      assert_equal 1, robot.x
      assert_equal 1, robot.y
    end

    should "移動先が空、地面、Lambda、Open Lambda Liftであれば移動可能であること" do
      pend
      mine = Mine.new(<<-'EOD')
#####
# \ #
# R.#
# O #
#####
      EOD
      assert_equal true, mine.robot.movable?(:left), "空"
      assert_equal true, mine.robot.movable?(:right), "地面"
      assert_equal true, mine.robot.movable?(:up), "Lambda"
      assert_equal true, mine.robot.movable?(:down), "Open Lambda Lift"
    end

    should "移動先が岩でもその先が空白なら移動可能であること" do
      pend
      mine = Mine.new(<<-'EOD')
#####
#R* #
#####
      EOD
      assert_equal true, mine.robot.movable?(:right)
    end

    should "移動先が岩でその先が空白じゃなければ移動不可であること" do
      pend
      mine = Mine.new(<<-'EOD')
#######
#  \  #
#  *  #
##*R**#
#  *  #
#  L  #
#######
      EOD
      assert_equal false, mine.robot.movable?(:left), "壁"
      assert_equal false, mine.robot.movable?(:right), "岩"
      assert_equal false, mine.robot.movable?(:up), "Lambda"
      assert_equal false, mine.robot.movable?(:down), "Closed Lambda Lift"
    end

    should "それ以外（壁かClosed Lambda Lift）なら移動不可であること" do
      pend
      mine = Mine.new(<<-'EOD')
####
#RL#
####
      EOD
      assert_equal false, mine.robot.movable?(:left), "壁"
      assert_equal false, mine.robot.movable?(:right), "Closed Lambda Lift"
    end

    should "移動可能なPosの配列を返せること" do
      pend
      mine = Mine.new(<<-'EOD')
#######
#     #
#  #  #
##*R* #
#  .  #
#     #
#######
      EOD
      assert_equal [Pos.new(5, 4), Pos.new(4, 3)], mine.robot.movable_positions
    end
  end
end
