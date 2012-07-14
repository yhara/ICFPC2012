class LambdaLifter
  class Pos
    include Comparable

    attr_reader :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end

    def <=>(other)
      [other.y, other.x] == [x, y]
    end
  end
end