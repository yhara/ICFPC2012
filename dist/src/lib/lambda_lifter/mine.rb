# -*- coding: utf-8 -*-
# シミュレータ
class LambdaLifter
  class Mine
    LAYOUTS = {
      'R' => :robot,
      '#' => :wall,
      '*' => :rock,
      '\\' => :lambda,
      'L' => :closed_lift,
      'O' => :open_lift,
      '.' => :earth,
      ' ' => :empty
    }

    COMMANDS = {
      'L' => :left,
      'R' => :right,
      'U' => :up,
      'D' => :down,
      'W' => :wait,
      'A' => :abort
    }

    attr_accessor :robot, :lambdas, :updated_map

    def initialize(mine_description)
      @map = nil
      parse(mine_description)
    end

    # 内部データを返す。
    def raw_map
      @map
    end

    # ゲーム座標の(x, y)にあるものをシンボルで返す。左下が(1, 1)
    # 引数はPosか、整数2つを渡す
    # 例： mine[pos], mine[1, 2]
    def [](arg1, arg2=nil)
      if arg2
        x, y = arg1, arg2
      else
        x, y = arg1.x, arg1.y
      end
      @map[@map.length - y][x - 1]
    end

    # マップを新規作成する。
    def step(command)
      # TODO
    end
  
    # マップを書き換える。
    def step!(command)
      @updated_map = @map.dup
      command = COMMAND[command]

      if @robot.movable?(command)
        set(@robot.x, @robot.y, :empty)
        case command
        when :left
          set(@robot.x - 1, @robot.y, :robot)
        when :right
          set(@robot.x + 1, @robot.y, :robot)
        when :up
          set(@robot.x, @robot.y + 1, :robot)
        when :down
          set(@robot.x, @robot.y - 1, :robot)
        end
      end

      # 岩を更新する
      width = 1
      height = 1
      while @height <= height
        while @width <= width
          layout = self[width, height]
          case layout
          when :rock
            if self[width, height - 1] == :empty
              set(width, height, :empty)
              set(width, height - 1, :rock)
            elsif self[width, height - 1] == :rock &&
                  self[width + 1, height] == :empty &&
                  self[width + 1, height - 1] == :empty
              set(width, height, :empty)
              set(width + 1, height - 1, :rock)
            elsif self[width, height - 1] == :rock &&
                  self[width + 1, height] != :empty &&
                  self[width - 1, height - 1] = :empty ||
                  self[width, height - 1] == :rock &&
                  self[width + 1, height - 1] != :empty &&
                  self[width - 1, height - 1] = :empty
              set(width, height, :empty)
              set(width - 1, height - 1, :rock)
            elsif self[width, height - 1] == :lambda &&
                  self[width + 1, height] == :empty &&
                  self[width + 1, height - 1] == :empty
              set(width, height, :empty)
              set(width + 1, height - 1, :rock)
            end
          when :closed_lift
            if @lambdas == 0
             set(width, height, :open_lift)
            end
          end
        width += 1
        end
        width = 0
        height += 1
      end
    end
  
    def finished?
     # TODO
     # :winning, :abort, :losing, falseのどれかを返す。
    end

    def losing?
      finished? == :losing
    end

    def winning?
      finished? == :winning
    end

    def abort?
      finished? == :abort
    end

    private

    def get(x, y)
      @updated_map[@updated_map.length - y][x - 1]
    end

    def set(x, y, layout)
      @updated_map[@updated_map.length - y][x - 1] = layout
    end

    def parse(mine_description)
      mine_description = mine_description.split("\n")
      @lambdas = 0
      grid = mine_description.each_with_object([]) do |line, g|
        g << line.each_char.map do |c|
          layout = LAYOUTS[c]
          if layout == :lambda
            @lambdas += 1
          end
          layout
        end
      end
      @width = grid.max {|m| m.length }.length
      @height = gird.length
      # 最大幅より短い行は、文字数が足りない分だけ:emptyを持たせる。
      @map = grid.map do |line|
        if line.length < @width
          line += Array.new(@width - line.length, :empty)
        end
        line
      end

      # TODO: 水位情報の取得
    end
  end
end
