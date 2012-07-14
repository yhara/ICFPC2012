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

    def initialize(mine_description)
      @map = nil
      parse(mine_description)
    end

    # 内部データを返す。
    def raw_map
      @map
    end

    # ゲーム座標の(x, y)にあるものをシンボルで返す。左下が(1, 1)
    def [](x, y)
      # TODO
    end

    # マップを新規作成する。
    def step(command)
      # TODO
    end
  
    # マップを書き換える。
    def step!(command)
      # TODO
    end
  
    def finished?
     # TODO
     # :winning, :abort, :losing, falseのどれかを返す。
    end

    private

    def parse(mine_description)
      mine_description = mine_description.split("\n")
      grid = mine_description.each_with_object([]) do |line, g|
        g << line.each_char.map {|c| LAYOUTS[c] }
      end
      longest_line_length = grid.max {|m| m.length }.length
      # 最大幅より短い行は、文字数が足りない分だけ:emptyを持たせる。
      @map = grid.map do |line|
        if line.length < longest_line_length
          line += Array.new(longest_line_length - line.length, :empty)
        end
        line
      end

      # TODO: 水位情報の取得
    end
  end
end
