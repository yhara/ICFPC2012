class LambdaLifter
  class Pos
    attr_reader :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end

    def <=>(other)
      [x, y] <=> [other.x, other.y]
    end
    include Comparable

    def inspect
      "(#{@x}, #{@y})"
    end

    def eql?(other)
      hash.eql?(other.hash)
    end

    def hash
      [x, y].hash
    end
  end
end
