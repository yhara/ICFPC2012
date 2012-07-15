require_relative 'hash_eqlable'

class LambdaLifter
  class Pos
    include HashEqlable

    attr_reader :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end

    def +(other)
      return self.class.new(x + other.x, y + other.y)
    end

    def -(other)
      return self.class.new(x - other.x, y - other.y)
    end

    def <=>(other)
      [x, y] <=> [other.x, other.y]
    end
    include Comparable

    def inspect
      "(#{@x}, #{@y})"
    end
    alias :to_s :inspect

    def hash
      [x, y].hash
    end
  end
end
