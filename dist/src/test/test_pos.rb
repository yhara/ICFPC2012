# coding: utf-8

class LambdaLifter
  class TestPos < Test::Unit::TestCase
    should ".x, .yでアクセスできること" do
      pos = Pos.new(1, 2)
      assert_equal 1, pos.x
      assert_equal 2, pos.y
    end

    should "Pos[]でインスタンスを作れること" do
      pos = Pos[1, 2]
      assert_equal 1, pos.x
      assert_equal 2, pos.y
    end

    should "+は引数のPos分増加した場所を返すこと" do
      pos = Pos.new(2, 5) + Pos.new(2, 1)
      assert_equal 4, pos.x
      assert_equal 6, pos.y
    end

    should "-は引数のPos分減算した場所を返すこと" do
      pos = Pos.new(2, 5) - Pos.new(1, 3)
      assert_equal 1, pos.x
      assert_equal 2, pos.y
    end

    should "inspect,aliasは(x, y)の文字列を返すこと" do
      assert_equal "(1, 2)", Pos.new(1, 2).inspect
      assert_equal "(1, 2)", Pos.new(1, 2).to_s
    end

    should "x, yを基にした比較が可能であること" do
      a = Pos.new(2, 5)
      b = Pos.new(2, 5)
      c = Pos.new(1, 2)
      assert_equal a, b
      assert a == b
      assert_equal false, a != b
      assert a != c
    end

    should "hashのkeyとして指定できること" do
      h = {}
      a = [Pos[1, 2], Pos[3, 4]]
      b = [Pos[1, 2], Pos[3, 4]]
      h[a] = true
      h[b] = true
      assert_equal 1, h.size
    end
  end
end
