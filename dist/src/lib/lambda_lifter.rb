require "logger"

class LambdaLifter
  def self.run
    mine = Mine.new(ARGF.read)
    solver = Solver.new(mine)
    print solver.solve
  end

  def self.logger
    if debug?
      @@logger ||= Logger.new(
        File.expand_path("debug.log",
          File.join(File.dirname(__FILE__), "../log")))
    else
      @@logger ||= Logger.new(nil)
    end
    return @@logger
  end

  def self.debug?
    !!ENV["DEBUG"]
  end
end

require_relative 'lambda_lifter/pos'
require_relative 'lambda_lifter/solver'
require_relative 'lambda_lifter/mine'
require_relative 'lambda_lifter/robot'
