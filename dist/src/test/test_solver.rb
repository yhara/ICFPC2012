# coding: utf-8
class LambdaLifter
  class TestSolver < Test::Unit::TestCase
    should "contest1.mapのsolve" do
      m = Mine.new(File.read(fixture_path("contest1.map")))
      s = Solver.new(m)
      p s.solve
    end
  end
end
