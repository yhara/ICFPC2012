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
      @original_map = <<-'EOD'.freeze
#######
#R\*. #
#####L#
      EOD
      @mine = Mine.new(@original_map)
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

    context "newが呼ばれたとき" do
      should "岩の位置を知っていること" do
        @mine = Mine.new(<<-'EOD')
####
# *#
#R*#
####
        EOD
        assert_equal [Pos.new(3, 3), Pos.new(3, 2)], @mine.rocks
      end
    end

    should "mine[x, y]でその座標にあるものを返すこと" do
      assert_equal :wall, @mine[1, 1] 
      assert_equal :robot, @mine[2, 2] 
      assert_equal :lambda, @mine[3, 2] 
    end

    should "hashのkeyとして指定できること" do
      mine2 = Mine.new(<<-'EOD')
#######
#R\*. #
#####L#
      EOD
      assert_equal @mine.hash, mine2.hash
      assert_equal true, @mine.eql?(mine2)

      h = {}
      h[@mine] = true
      h[mine2] = true
      assert_equal 1, h.size
    end

    should "ascii_mapでマップの文字列表現を返すこと" do
      assert_equal @original_map, @mine.ascii_map

      original_map_2 = <<-'EOD'.freeze
####
#RO#
####
      EOD
      mine_2 = Mine.new(original_map_2)
      assert_equal original_map_2, mine_2.ascii_map, "Open Lambda Lift確認"
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
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("W")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[2]
      end

      should "コマンドRLでロボットが元の位置に戻ること" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("R")
        assert_equal [:wall, :empty, :empty, :robot, :wall], mine.raw_map[2]
        mine.step!("L")
        assert_equal [:wall, :empty, :robot, :empty, :wall], mine.raw_map[2]
      end

      should "存在しないコマンドは例外が発生すること" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        assert_raise(UnknownCommandError) do
          mine.step!("(")
        end
      end

      should "ロボットの移動に成功するとスコアが-1減ること" do
        mine = Mine.new(ROBOT_CENTERED_MAP)
        mine.step!("R")
        assert_equal -1, mine.score
        mine.step!("L")
        assert_equal -2, mine.score
        mine.step!("U")
        assert_equal -3, mine.score
        mine.step!("D")
        assert_equal -4, mine.score
        mine.step!("W")
        assert_equal -4, mine.score
      end

      should "ロボットの移動に伴い岩が移動すること" do
        mine = Mine.new(<<-'EOD')
#######
# *R* #
#######
        EOD
        assert_equal [:wall, :empty, :rock, :robot, :rock, :empty, :wall],
                     mine.raw_map[1]
        mine.step!("L")
        assert_equal [:wall, :rock, :robot, :empty, :rock, :empty, :wall],
                     mine.raw_map[1]
        mine.step!("R")
        mine.step!("R")
        assert_equal [:wall, :rock, :empty, :empty, :robot, :rock, :wall],
                     mine.raw_map[1]
      end

      should "岩が落下すること" do
        mine = Mine.new(<<-'EOD')
R##
#*#
# #
###
        EOD
        assert_equal [:wall, :rock,  :wall], mine.raw_map[1]
        mine.step!("W")
        assert_equal [:wall, :empty, :wall], mine.raw_map[1]
        assert_equal [:wall, :rock,  :wall], mine.raw_map[2]
      end

      should "岩が左右に崩落すること" do
        mine = Mine.new(<<-'EOD')
R#####
#*  *#
#*  *#
######
        EOD
        assert_equal [:wall, :rock, :empty, :empty, :rock, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock, :empty, :empty, :rock, :wall],
                     mine.raw_map[2]
        mine.step!("W")
        assert_equal [:wall, :empty, :empty, :empty, :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock,  :rock,  :rock,  :rock,  :wall],
                     mine.raw_map[2]
      end

      should "先にupdateされたlayoutが後のupdateに影響されないこと" do
        # 2.3 Map Update の Note: の記述参考
        mine = Mine.new(<<-'EOD')
R####
#* *#
#* *#
#####
        EOD
        assert_equal [:wall, :rock, :empty, :rock, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock, :empty, :rock, :wall],
                     mine.raw_map[2]
        mine.step!("W")
        assert_equal [:wall, :empty, :empty, :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock,  :rock,  :rock,  :wall],
                     mine.raw_map[2]
      end

      should "ラムダの上の岩は右側に崩落すること" do
        mine = Mine.new(<<-'EOD')
R####
# * #
# \ #
#####
        EOD
        assert_equal [:wall, :empty, :rock,   :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :lambda, :empty, :wall],
                     mine.raw_map[2]
        mine.step!("W")
        assert_equal [:wall, :empty, :empty,  :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :lambda, :rock,  :wall],
                     mine.raw_map[2]
      end

      should "ラムダの上の岩は左側に崩落しないこと" do
        mine = Mine.new(<<-'EOD')
R###
# *#
# \#
####
        EOD
        assert_equal [:wall, :empty, :rock,   :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :lambda, :wall],
                     mine.raw_map[2]
        mine.step!("W")
        assert_equal [:wall, :empty, :empty,  :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :rock,  :lambda, :wall],
                     mine.raw_map[2]
      end

      should "ロボットによる岩の移動と更新による岩の移動は区別されていること" do
        mine = Mine.new(<<-'EOD')
#####
#R* #
# * #
#####
        EOD
        assert_equal [:wall, :robot, :rock,   :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :rock,   :empty, :wall],
                     mine.raw_map[2]
        mine.step!("R")
        assert_equal [:wall, :empty, :robot,  :empty, :wall],
                     mine.raw_map[1]
        assert_equal [:wall, :empty, :rock,   :rock,  :wall],
                     mine.raw_map[2]
      end
    end

    should "ラムダの上にRがきたらlamdasは消えること" do
      @mine = Mine.new(<<-'EOD')
#######
#R\*. #
#####L#
      EOD
      @mine.step!("R")
      assert_equal true, @mine.lambdas.empty?
    end

    context "dupが呼ばれたとき" do
      should "内部のmapを複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.raw_map, mine2.raw_map
        assert_not_equal @mine.raw_map.object_id, mine2.raw_map.object_id
      end

      should "内部のrobotを複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.robot, mine2.robot
        assert_not_equal @mine.robot.object_id, mine2.robot.object_id
      end

      should "内部のlambdasを複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.lambdas, mine2.lambdas
        assert_not_equal @mine.lambdas.object_id, mine2.lambdas.object_id
      end

      should "その他の情報を複製すること" do
        mine2 = @mine.dup

        assert_equal @mine.width, mine2.width
        assert_equal @mine.height, mine2.height
        assert_equal @mine.lift, mine2.lift
        assert_equal @mine.commands, mine2.commands
        assert_equal @mine.rocks, mine2.rocks
        assert_not_equal @mine.commands.object_id, mine2.commands.object_id
        assert_not_equal @mine.rocks.object_id, mine2.rocks.object_id
        assert_not_equal @mine.lambdas.object_id, mine2.lambdas.object_id
      end
    end

    context "finished?が呼ばれたとき" do
      should ":winningを返すこと" do
        pend
        mine = Mine.new(<<-'EOD')
#####
#R\L#
#####
        EOD
        mine.step!("R")
        mine.step!("R")
        assert_equal :winning, mine.finished?
      end

      should ":abortを返すこと" do
        pend
        mine = Mine.new(<<-'EOD')
#####
#R  #
#####
        EOD
        mine.step!("A")
        assert_equal :abort, mine.finished?
      end

      should ":losingを返すこと" do
        pend
        mine = Mine.new(<<-'EOD')
#####
#*  #
#   #
#  R#
#####
        EOD
        mine.step!("L")

        assert_equal :losing, mine.finished?
      end

      should "falseを返すこと" do
        mine = Mine.new(<<-'EOD')
#####
#R  #
#####
        EOD
        assert_equal false, mine.finished?
      end
    end
  end
end
