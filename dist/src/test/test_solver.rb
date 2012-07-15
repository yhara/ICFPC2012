# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
    should "回答不可能な小さいマップがハイスコアでabortすること" do
      desc = <<-'EOD'.freeze
######
#. *R#
L* .\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      # ハイスコア状態でabort
      s.solve
      assert_equal "DA", s.solve
    end

    should "回答可能な小さいマップが解けること" do
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
      desc = <<-'EOD'.freeze
######
#. *R#
#  \.#
#\ * #
L  .\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      assert_equal "LDLLDRRDRLULLDL", s.solve
    end

    should "solve_to_checkpointでcheckpointまでの経路をA*探索で導くこと" do
      desc = <<-'EOD'.freeze
######
#. *R#
#  \.#
#\ * #
L  .\#
######
      EOD
      m = Mine.new(desc)
      s = Solver.new(m)
      assert_equal true, s.send(:solve_to_checkpoint, Pos.new(5, 2))
    end
  end
end
