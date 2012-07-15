# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
    should "回答不可能な小さいマップがハイスコアでabortすること" do
      pend
      desc = <<-'EOD'.freeze
######
#. *R#
L *.\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      # ハイスコア状態でabort
      assert_equal "DA", s.solve
    end

    should "回答可能な小さいマップが解けること" do
      pend
      desc = <<-'EOD'.freeze
######
#.* R#
L ..\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      # ハイスコア状態でabort
      assert_equal "DLLLL", s.solve
    end

    should "limit_commands_exceeded?がサイズオーバーの時にtrueを返す" do
      desc = <<-'EOD'.freeze
###
LR#
###
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      s.instance_variable_set(:@commands, (0..(m.width * m.height+1)).map.to_a)
      assert_equal true, s.send(:limit_commands_exceeded?)
    end

    should "contest1.mapのsolve" do
      pend
      desc = <<-'EOD'.freeze
######
#. *R#
#  \.#
#\ * #
L  .\#
######
      EOD
      m = Mine.new(map)
      s = Solver.new(m)
      p s.solve
    end

    should "solve_to_checkpointでcheckpointまでの経路をA*探索で導くこと" do
      pend
      # ######
      # #. *R#
      # #  \.#
      # #\ * #
      # L  .\#
      # ######
      m = Mine.new(File.read(fixture_path("contest1.map")))
      s = Solver.new(m)
      assert_equal true, s.send(:solve_to_checkpoint, Pos.new(5, 2))
    end
  end
end
