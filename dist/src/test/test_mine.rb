# coding: utf-8

class LambdaLifter
  class TestMine < Test::Unit::TestCase

    ROBOT_CENTERED_MAP = <<-'EOD'
#####
#   #
# R #
#   #
#####
        EOD

    setup do
      @mine = Mine.new(<<-'EOD')
#######
#R\*. #
#####L#
      EOD
    end

    should "マップ定義からシンボルの２次元配列を作れること" do
      desc = <<-'EOD'
#######
#R\*. #
#####L#
      EOD

      expected = [
        [:wall, :wall,  :wall,   :wall, :wall,  :wall,  :wall],
        [:wall, :robot, :lambda, :rock, :earth, :empty, :wall],
        [:wall, :wall,  :wall,   :wall, :wall,  :closed_lift,  :wall],
      ]

      mine = Mine.new(desc)

      assert_equal expected, mine.raw_map
    end

    should "mine[x, y]でその座標にあるものを返すこと" do
      assert_equal :wall, @mine[1, 1] 
      assert_equal :robot, @mine[2, 2] 
      assert_equal :lambda, @mine[3, 2] 
    end

    context "step!が呼ばれたとき" do
      should "コマンドRでロボットを右に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("R")
        assert_equal [:wall, :empty, :empty, :robot, :wall], mine.raw_map[2]
      end

      should "コマンドLでロボットを左に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("L")
        assert_equal [:wall, :robot, :empty, :empty, :wall], mine.raw_map[2]
      end

      should "コマンドUでロボットを上に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("U")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[1]
      end

      should "コマンドDでロボットを下に動かすこと" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("D")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[3]
      end

      should "コマンドWでロボットが動かないこと" do
        pend
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("W")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[2]
      end

      should "コマンドRLでロボットが元の位置に戻ること" do
        pend
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("R")
        assert_equal [:wall, :empty, :empty, :robot, :wall], mine.raw_map[2]
        mine.step!("L")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[2]
      end
    end

  end
end
