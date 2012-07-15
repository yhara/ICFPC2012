# -*- coding: utf-8 -*-
# シミュレータ
class LambdaLifter
  class UnknownCommandError < StandardError; end

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
      ' ' => :empty,
      'A' => :trampoline_a,
      'B' => :trampoline_b,
      'C' => :trampoline_c,
      'D' => :trampoline_d,
      'E' => :trampoline_e,
      'F' => :trampoline_f,
      'G' => :trampoline_g,
      'H' => :trampoline_h,
      'I' => :trampoline_i,
      '1' => :target_1,
      '2' => :target_2,
      '3' => :target_3,
      '4' => :target_4,
      '5' => :target_5,
      '6' => :target_6,
      '7' => :target_7,
      '8' => :target_8,
      '9' => :target_9
    }.freeze

    COMMANDS = {
      'L' => :left,
      'R' => :right,
      'U' => :up,
      'D' => :down,
      'W' => :wait,
      'A' => :abort
    }.freeze

    GIVEN_SCORES = {
      :each_move                => -1,
      :collect_lambda           => 25,
      :collected_lambda_abort   => 25,
      :collected_lambda_win     => 50,
    }.freeze

    attr_accessor :robot, :lambdas, :lift, :rocks
    attr_reader :width, :height, :commands, :score, :water, :flooding,
      :number_of_flooding, :waterproof, :number_of_waterproof,
      :trampolines, :targets, :trampoline_relationships,
      :growth, :razors

    def initialize(mine_description)
      unless mine_description.nil?
        @map = nil
        @rocks = []
        @lambdas = []
        @score = 0
        @water = 0
        @flooding = 0
        @number_of_flooding = 0
        @waterproof = 10
        @number_of_waterproof = 0
        @trampolines = []
        @targets = []
        @trampoline_relationships = {}
        @growth = 0
        @razors = 0
        parse(mine_description)
        @updated_map = @map.dup
        @commands = []
        @number_of_collected_lambdas = 0
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
      mine.instance_variable_set(:@map, Marshal.load(Marshal.dump(@map)))
      robot = Robot.new(mine, @robot.x, @robot.y)
      mine.instance_variable_set(:@robot, robot)
      mine.instance_variable_set(:@lambdas, @lambdas.dup)
      mine.instance_variable_set(:@width, @width)
      mine.instance_variable_set(:@height, @height)
      mine.instance_variable_set(:@lift, @lift)
      mine.instance_variable_set(:@commands, @commands.dup)
      mine.instance_variable_set(:@rocks, @rocks.dup)
      mine.instance_variable_set(:@score, @score)
      mine.instance_variable_set(:@water, @water)
      mine.instance_variable_set(:@flooding, @flooding)
      mine.instance_variable_set(:@number_of_flooding, @number_of_flooding)
      mine.instance_variable_set(:@waterproof, @waterproof)
      mine.instance_variable_set(:@number_of_waterproof, @number_of_waterproof)
      mine.instance_variable_set(:@number_of_collected_lambdas,
                                  @number_of_collected_lambdas)
      mine.instance_variable_set(:@trampolines,
        Marshal.load(Marshal.dump(@trampolines)))
      mine.instance_variable_set(:@targets,
        Marshal.load(Marshal.dump(@targets)))
      mine.instance_variable_set(:@trampoline_relationships,
        Marshal.load(Marshal.dump(@trampoline_relationships)))
      mine.instance_variable_set(:@growth, @growth)
      mine.instance_variable_set(:@razors, @razors)
      return mine
    end

    def hash
      raw_map.hash
    end

    def ascii_map
      return array_to_ascii_map(@map)
    end

    # マップを新規作成する。
    def step(command)
      # TODO
    end
  
    # マップを書き換える。
    def step!(command)
      raise "This mine is already finished" if finished?

      @command = COMMANDS[command]
      raise UnknownCommandError if @command.nil?
      @commands << command

      if @robot.movable?(@command)
        self[@robot.x, @robot.y] = :empty

        layout = case @command
                 when :left
                   self[@robot.x - 1, @robot.y]
                 when :right
                   self[@robot.x + 1, @robot.y]
                 when :up
                   self[@robot.x, @robot.y + 1]
                 when :down
                   self[@robot.x, @robot.y - 1]
                 end

        case layout
        when :rock
          process_rock(@command)
        when :lambda
          process_lambda(@command)
        when :open_lift
          process_open_lift
        end
        process_robot(@command)
        if /trampoline_\w/ =~ layout
          process_trampoline(layout)
        end
      end

      # 岩を更新する
      @updated_map = Marshal.load(Marshal.dump(@map))
      process_map

      if @command == :abort
        @abort = true
        @score += GIVEN_SCORES[:collected_lambda_abort] * @number_of_collected_lambdas
      end
      if self[@robot.x, @robot.y + 1] == :empty &&
         get(@robot.x, @robot.y + 1) == :rock
        @losing = true
      end
      @map = @updated_map

      if underwater?
        @number_of_waterproof += 1
      else
        @number_of_waterproof = 0
      end
      water_rising
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

    def process_map
      _rocks = @rocks.dup
      _rocks.each do |rock|
        if self[rock.x, rock.y - 1] == :empty
          set(rock.x, rock.y, :empty)
          set(rock.x, rock.y - 1, :rock)
          @rocks.delete(Pos[rock.x, rock.y])
          @rocks << Pos[rock.x, rock.y - 1]
        elsif self[rock.x,     rock.y - 1] == :rock  &&
              self[rock.x + 1, rock.y    ] == :empty &&
              self[rock.x + 1, rock.y - 1] == :empty
          set(rock.x, rock.y, :empty)
          set(rock.x + 1, rock.y - 1, :rock)
          @rocks.delete(Pos[rock.x, rock.y])
          @rocks << Pos[rock.x + 1, rock.y - 1]
        elsif self[rock.x,     rock.y - 1] == :rock       &&
              (self[rock.x + 1, rock.y    ] != :empty ||
               self[rock.x + 1, rock.y - 1] != :empty)    &&
              self[rock.x - 1, rock.y    ] == :empty      &&
              self[rock.x - 1, rock.y - 1] == :empty
          set(rock.x, rock.y, :empty)
          set(rock.x - 1, rock.y - 1, :rock)
          @rocks.delete(Pos[rock.x, rock.y])
          @rocks << Pos[rock.x - 1, rock.y - 1]
        elsif self[rock.x,     rock.y - 1] == :lambda &&
              self[rock.x + 1, rock.y    ] == :empty  &&
              self[rock.x + 1, rock.y - 1] == :empty
          set(rock.x, rock.y, :empty)
          set(rock.x + 1, rock.y - 1, :rock)
          @rocks.delete(Pos[rock.x, rock.y])
          @rocks << Pos[rock.x + 1, rock.y - 1]
        end
      end

      if @lift && @lambdas.length == 0 && self[@lift.x, @lift.y] == :closed_lift
        set(@lift.x, @lift.y, :open_lift)
      end
    end

    def process_rock(direction) 
      case direction
      when :left
        self[@robot.x - 2, @robot.y] = :rock
        @rocks.delete(Pos[@robot.x - 1, @robot.y])
        @rocks << Pos[@robot.x - 2, @robot.y]
      when :right
        self[@robot.x + 2, @robot.y] = :rock
        @rocks.delete(Pos[@robot.x + 1, @robot.y])
        @rocks << Pos[@robot.x + 2, @robot.y]
      end
    end

    def process_lambda(direction)
      case direction
      when :left
        @lambdas.delete(Pos.new(@robot.x - 1, @robot.y))
      when :right
        @lambdas.delete(Pos.new(@robot.x + 1, @robot.y))
      when :up
        @lambdas.delete(Pos.new(@robot.x, @robot.y + 1))
      when :down
        @lambdas.delete(Pos.new(@robot.x, @robot.y - 1))
      end
      @number_of_collected_lambdas += 1
      @score += GIVEN_SCORES[:collect_lambda]
    end

    def process_open_lift
      @winning = true
      @score += GIVEN_SCORES[:collected_lambda_win] *
                @number_of_collected_lambdas
    end

    def process_robot(direction)
      case direction
      when :left
        self[@robot.x - 1, @robot.y] = :robot
        @robot = Robot.new(self, @robot.x - 1, @robot.y)
      when :right
        self[@robot.x + 1, @robot.y] = :robot
        @robot = Robot.new(self, @robot.x + 1, @robot.y)
      when :up
        self[@robot.x, @robot.y + 1] = :robot
        @robot = Robot.new(self, @robot.x, @robot.y + 1)
      when :down
        self[@robot.x, @robot.y - 1] = :robot
        @robot = Robot.new(self, @robot.x, @robot.y - 1)
      end
      @score += GIVEN_SCORES[:each_move]
    end

    def process_trampoline(layout)
      target = @trampoline_relationships[layout]
      pos = @targets[target]
      self[@robot.x, @robot.y] = :empty

      deleted_trampolines = @trampoline_relationships.select {|_, v|
        v == target }
      @trampoline_relationships.reject! {|k, _|
        deleted_trampolines.keys.include?(k) }
      deleted_trampolines.keys.uniq.each do |t|
        set(@trampolines[t].x, @trampolines[t].y, :empty)
        @trampolines.delete(t)
      end
      deleted_trampolines.values.uniq.each do |t|
        set(@targets[t].x, @targets[t].y, :empty)
        @targets.delete(t)
      end

      self[pos.x, pos.y] = :robot
      @robot = Robot.new(self, pos.x, pos.y)
    end

    def []=(game_x, game_y, val)
      ruby_x, ruby_y = ruby_axis(game_x, game_y)
      @map[ruby_y][ruby_x] = val
    end

    def ruby_axis(game_x, game_y)
      return game_x - 1, @map.length - game_y
    end

    def game_axis(ruby_x, ruby_y)
      return ruby_x + 1, height - ruby_y
    end

    def get(x, y)
      @updated_map[@updated_map.length - y][x - 1]
    end

    def set(x, y, layout)
      @updated_map[@updated_map.length - y][x - 1] = layout
    end

    def array_to_ascii_map(ary)
      # デバッグ時に@updated_mapを見るときのためにあえて、
      # 引数に配列の配列を取るインスタンスメソッドを用意した。
      @@inverted_layouts ||= LAYOUTS.invert.freeze
      return ary.map do |row|
        row.map do |cell|
          @@inverted_layouts[cell]
        end.join + "\n"
      end.join
    end

    def underwater?
      return @robot.y <= @water
    end

    def water_rising
      return if @flooding == 0
      @number_of_flooding += 1
      if @number_of_flooding >= @flooding 
        @water += 1
        @number_of_flooding = 0
      end
    end

    def parse_mine_params(line)
      if line.match(/^(Water|Flooding|Waterproof|Growth|Razors) (\d+)/)
        self.instance_variable_set("@" + $1.downcase, $2.to_i)
        return true
      elsif line.match(/^Trampoline (\w) targets (\d)/)
        @trampoline_relationships[LAYOUTS[$1]] = LAYOUTS[$2]
        return true
      else
        return false
      end
    end

    def parse(mine_description)
      _mine_description = mine_description.split("\n")
      _lambdas = []
      _lift = []
      _rocks = []
      _trampolines = []
      _targets = []
      robot_ruby_x = nil
      robot_ruby_y = nil
      grid = _mine_description.each_with_object([]).with_index do |(line, g), y|
        got_param = parse_mine_params(line)
        next if got_param || line.strip.chomp.empty?
        g << line.each_char.map.with_index do |c, x|
          layout = LAYOUTS[c]
          case layout
          when :rock
            _rocks << [x, y]
          when :lambda
            _lambdas << [x, y]
          when :closed_lift
            _lift = [x, y]
          when :robot
            robot_ruby_x = x
            robot_ruby_y = y
          when /trampoline_\w/
            _trampolines << [layout, x, y]
          when /target_\d/
            _targets << [layout, x, y]
          end
          layout
        end
      end
      @width = grid.max {|m| m.length }.length
      @height = grid.length
      @lambdas = _lambdas.map {|x, y| Pos.new(*game_axis(x, y)) }
      if _lift.any?
        @lift = Pos.new(*game_axis(_lift[0], _lift[1]))
      end
      if _rocks.any?
        @rocks = _rocks.map {|x, y| Pos.new(*game_axis(x, y)) }
      end
      if _trampolines.any?
        @trampolines = _trampolines.each_with_object({}) {|(l, x, y), h|
          h.merge!(l => Pos.new(*game_axis(x, y))) }
      end
      if _targets.any?
        @targets = _targets.each_with_object({}) {|(l, x, y), h|
          h.merge!(l => Pos.new(*game_axis(x, y))) }
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
