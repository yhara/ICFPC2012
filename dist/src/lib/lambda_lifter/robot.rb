# -*- coding: utf-8 -*-
require 'forwardable'

class LambdaLifter
  class Robot
    extend Forwardable
    include Comparable

    attr_reader :pos
    def_delegators(:@pos, :x, :y, :<=>)

    def initialize(mine, x, y)
      @mine = mine
      @pos = Pos.new(x, y)
    end

    def movable_positions
      return DIRECTION_TO_DELTA.map do |direction, delta|
        movable?(direction) ? pos + delta : nil
      end.compact
    end

    def movable?(direction)
      delta = DIRECTION_TO_DELTA[direction]
      return nil if !delta
      new_pos = pos + delta
      case @mine[new_pos]
      when :empty, :earth, :lambda, :open_lift
        return true
      when :rock
        return delta.y.zero? && @mine[new_pos + delta] == :empty
      else
        return false
      end
    end

    def command_to(position)
      return DELTA_TO_COMMAND[position - pos]
    end

    private

    DIRECTION_TO_DELTA = {
      left:  Pos.new(-1,  0),
      right: Pos.new(+1,  0),
      up:    Pos.new( 0, +1),
      down:  Pos.new( 0, -1),
    }.freeze

    h = DIRECTION_TO_DELTA.merge(wait: Pos.new(0, 0))
    DELTA_TO_COMMAND = h.each_with_object({}) do |(dir, delta), o|
      o[delta] = Mine::COMMANDS.rassoc(dir).first
    end.freeze
  end
end
