# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
    should "回答不可能な小さいマップがハイスコアでabortすること" do
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
