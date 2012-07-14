# coding: utf-8

class LambdaLifter
  class TestRobot < Test::Unit::TestCase
    should ".x, .yでアクセスできること" do
      robot = LambdaLifter::Robot.new(nil, 2, 3)
      assert_equal 2, robot.x
      assert_equal 3, robot.y
    end

    context "movable?が呼ばれたとき" do
      should "移動先が空、地面、Lambda、Open Lambda Liftであれば移動可能であること" do
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
        mine = Mine.new(<<-'EOD')
#####
#R* #
#####
        EOD
        assert_equal true, mine.robot.movable?(:right)
      end

      should "移動先が岩でその先が空白じゃなければ移動不可であること" do
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
        mine = Mine.new(<<-'EOD')
####
#RL#
####
        EOD
        assert_equal false, mine.robot.movable?(:left), "壁"
        assert_equal false, mine.robot.movable?(:right), "Closed Lambda Lift"
      end

      should "移動コマンドでなければnilを返すこと" do
        mine = Mine.new(<<-'EOD')
####
#RL#
####
        EOD
        assert_equal nil, mine.robot.movable?(:wait)
        assert_equal nil, mine.robot.movable?(:abort)
      end
    end

    should "移動可能なPosの配列を返せること" do
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

    should "command_toは移動に使うコマンドを返せること" do
      x = 2
      y = 3
      robot = LambdaLifter::Robot.new(nil, x, y)
      assert_equal 'L', robot.command_to(Pos.new(x - 1, y    ))
      assert_equal 'R', robot.command_to(Pos.new(x + 1, y    ))
      assert_equal 'U', robot.command_to(Pos.new(x    , y + 1))
      assert_equal 'D', robot.command_to(Pos.new(x    , y - 1))
      assert_equal 'W', robot.command_to(Pos.new(x    , y    ))
    end
  end
end
