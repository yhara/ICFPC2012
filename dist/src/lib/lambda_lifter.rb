class LambdaLifter
  def self.run
    mine = Mine.new(ARGF.read)
    solver = Solver.new(mine)
    return solver.solve
  end
end

require_relative 'lambda_lifter/pos'
require_relative 'lambda_lifter/solver'
require_relative 'lambda_lifter/mine'

if $0 == __FILE__
  # TODO: LambdaLifter.run
  puts("A")
end
