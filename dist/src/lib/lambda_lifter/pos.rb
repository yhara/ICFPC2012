class LambdaLifter
  class Pos
    include Comparable

    attr_accessor :x, :y
    def initialize(x, y)
      move_to(x, y)
    end

    def move_to(x, y)
      @x = x
      @y = y
    end

    def left
      @x=-1
    end

    def right
      @x=+1
    end

    def down
      @y=-1
    end

    def up
      @y=+1
    end

    def <=>(other)
      [other.y, other.x] == [x, y]
    end
  end
end
