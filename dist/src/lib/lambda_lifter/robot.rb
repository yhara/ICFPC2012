# -*- coding: utf-8 -*-
class LambdaLifter
  class Robot
    extend Forwardable

    attr_reader :pos
    def_delegators(:@pos, :x, :y)

    def initialize(map, x, y)
      @map = map
      @pos = Pos.new(x, y)
    end

    def movable_positions
      return DIRECTION_TO_DELTA.map do |direction, delta|
        movable?(direction) ? pos + delta : nil
      end.compact
    end

    def movable?(direction)
      delta = DIRECTION_TO_DELTA[direction]
      new_pos = pos + delta
      case @map[new_pos]
      when :empty, :earth, :lambda, :open_lift
        return true
      when :rock
        return delta.y.zero? && @map[new_pos + delta] == :empty
      else
        return false
      end
    end

    private

    DIRECTION_TO_DELTA = {
      left:  Pos.new(-1,  0),
      right: Pos.new(+1,  0),
      up:    Pos.new( 0, +1),
      down:  Pos.new( 0, -1),
    }
  end
end
