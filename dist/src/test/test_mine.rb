# coding: utf-8

class LambdaLifter
  class TestMine < Test::Unit::TestCase
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

    context "step!が呼ばれたとき" do
      should "ロボットを動かすこと" do
        mine = Mine.new(<<-'EOD')
####
#R #
####
        EOD
        mine.step!("R")

        assert_equal [:wall, :empty, :robot, :wall], mine.raw_map[1]
      end
    end

  end
end
