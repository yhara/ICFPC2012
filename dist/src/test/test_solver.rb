# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
    should "contest1.mapのsolve" do
      pend
      m = Mine.new(File.read(fixture_path("contest1.map")))
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
