# -*- coding: utf-8 -*-
# シミュレータ
class LambdaLifter
  class RobotUnmovableError < StandardError; end

  class Mine
    include HashEqlable

    LAYOUTS = {
      'R' => :robot,
      '#' => :wall,
      '*' => :rock,
      '\\' => :lambda,
      'L' => :closed_lift,
      'O' => :open_lift,
      '.' => :earth,
      ' ' => :empty
    }.freeze

    COMMANDS = {
      'L' => :left,
      'R' => :right,
      'U' => :up,
      'D' => :down,
      'W' => :wait,
      'A' => :abort
    }.freeze

    attr_accessor :robot, :lambdas, :lift
    attr_reader :width, :height, :commands

    def initialize(mine_description)
      unless mine_description.nil?
        @map = nil
        parse(mine_description)
        @updated_map = @map.dup
        @commands = []
      end
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

    # 自分自身を複製したMineオブジェクトを返す。
    def dup
      mine = Mine.new(nil)
      mine.instance_variable_set(:@map, @map.dup)
      robot = Robot.new(mine, @robot.x, @robot.y)
      mine.instance_variable_set(:@robot, robot)
      mine.instance_variable_set(:@lambdas, @lambdas.dup)
      mine.instance_variable_set(:@width, @width)
      mine.instance_variable_set(:@height, @height)
      mine.instance_variable_set(:@lift, @lift)
      mine.instance_variable_set(:@commands, @commands)
      return mine
    end

    def hash
      raw_map.hash
    end

    # マップを新規作成する。
    def step(command)
      # TODO
    end
  
    # マップを書き換える。
    def step!(command)
      @updated_map = @map.dup
      @command = COMMANDS[command]

      if @command
        @commands << @command
      else
        raise RobotUnmovableError
      end

      if @robot.movable?(@command)
        set(@robot.x, @robot.y, :empty)
        case @command
        when :left
          if self[@robot.x - 1, @robot.y] == :rock
            # このフェイズでの岩の動きは直後の更新時に影響するものであ
            # るため、@map を直接書き換える。
            set(@robot.x - 2, @robot.y, :rock)
          end
          if self[@robot.x - 1, @robot.y] == :lambda
            @lambdas.delete(Pos.new(@robot.x - 1, @robot.y))
          end
          set(@robot.x - 1, @robot.y, :robot)
          @robot = Robot.new(self,
            @robot.x - 1, @robot.y)
        when :right
            # 同上。
          if self[@robot.x + 1, @robot.y] == :rock
            self[@robot.x + 2, @robot.y] = :rock
          end
          if self[@robot.x + 1, @robot.y] == :lambda
            @lambdas.delete(Pos.new(@robot.x + 1, @robot.y))
          end
          set(@robot.x + 1, @robot.y, :robot)
          @robot = Robot.new(self,
            @robot.x + 1, @robot.y)
        when :up
          if self[@robot.x, @robot.y + 1] == :lambda
            @lambdas.delete(Pos.new(@robot.x, @robot.y + 1))
          end
          set(@robot.x, @robot.y + 1, :robot)
          @robot = Robot.new(self,
            @robot.x, @robot.y + 1)
        when :down
          if self[@robot.x, @robot.y - 1] == :lambda
            @lambdas.delete(Pos.new(@robot.x, @robot.y - 1))
          end
          set(@robot.x, @robot.y - 1, :robot)
          @robot = Robot.new(self,
            @robot.x, @robot.y - 1)
        end
      end

      # 岩を更新する
      width = 1
      height = 1
      while height <= @height
        while width <= @width
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
                  self[width - 1, height - 1] == :empty ||
                  self[width, height - 1] == :rock &&
                  self[width + 1, height - 1] != :empty &&
                  self[width - 1, height - 1] == :empty
              set(width, height, :empty)
              set(width - 1, height - 1, :rock)
            elsif self[width, height - 1] == :lambda &&
                  self[width + 1, height] == :empty &&
                  self[width + 1, height - 1] == :empty
              set(width, height, :empty)
              set(width + 1, height - 1, :rock)
            end
          when :closed_lift
            if @lambdas.length == 0
             set(width, height, :open_lift)
            end
          end
        width += 1
        end
        width = 0
        height += 1
      end

      if self[@robot.x, @robot.y] == :open_lift && @lambdas.length == 0
        @winning = true
      end
      if @command == :abort
        @abort = true
      end
      if self[@robot.x, @robot.y + 1] == :empty &&
         get(@robot.x, @robot.y + 1) == :rock
        @losing = true
      end
      @map = @updated_map
      return
    end
  
    def finished?
     # :winning, :abort, :losing, falseのどれかを返す。
     if @winning
       return :winning
     end
     if @abort
       return :abort
     end
     if @losing
       return :losing
     end
     return false
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

    def game_axis(ruby_x, ruby_y)
      return ruby_x + 1, height - ruby_y
    end

    def get(x, y)
      @updated_map[@updated_map.length - y][x - 1]
    end

    def set(x, y, layout)
      @updated_map[@updated_map.length - y][x - 1] = layout
    end

    def parse(mine_description)
      mine_description = mine_description.split("\n")
      _lambdas = []
      _lift = []
      robot_ruby_x = nil
      robot_ruby_y = nil
      grid = mine_description.each_with_object([]).with_index do |(line, g), y|
        g << line.each_char.map.with_index do |c, x|
          layout = LAYOUTS[c]
          case layout
          when :lambda
            _lambdas << [x, y]
          when :closed_lift
            _lift = [x, y]
          when :robot
            robot_ruby_x = x
            robot_ruby_y = y
          end
          layout
        end
      end
      @width = grid.max {|m| m.length }.length
      @height = grid.length
      if _lambdas.any?
        @lambdas = _lambdas.map {|x, y| Pos.new(*game_axis(x, y)) }
      end
      if _lift.any?
        @lift = Pos.new(*game_axis(_lift[0], _lift[1]))
      end
      @robot = Robot.new(self,
                         *game_axis(robot_ruby_x, robot_ruby_y))
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
