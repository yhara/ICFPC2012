# coding: utf-8

class TestPos < Test::Unit::TestCase
  should ".x, .yでアクセスできること" do
    pos = LambdaLifter::Pos.new(1, 1)
    assert_equal 1, pos.x
    assert_equal 1, pos.y
  end

  should "inspectは(x, y)の文字列を返すこと" do
    assert_equal "(1, 2)", LambdaLifter::Pos.new(1, 2).inspect
  end

  should "x, yを基にした比較が可能であること" do
    a = LambdaLifter::Pos.new(1, 1)
    b = LambdaLifter::Pos.new(1, 1)
    c = LambdaLifter::Pos.new(1, 2)
    assert_equal a, b
    assert a == b
    assert a != c
  end

  should "hashのkeyとして指定できること" do
    h = {}
    a = LambdaLifter::Pos.new(1, 2)
    b =  LambdaLifter::Pos.new(1, 2)
    h[a] = true
    h[b] = true
    assert a.eql?(b)
    assert_equal a.hash, b.hash
    assert_equal 1, h.keys.size
  end
end
