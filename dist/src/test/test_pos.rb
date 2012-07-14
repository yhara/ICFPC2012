# coding: utf-8

class TestPos < Test::Unit::TestCase
  should ".x, .yでアクセスできること" do
    pos = LambdaLifter::Pos.new(1, 1)
    assert_equal 1, pos.x
    assert_equal 1, pos.y
  end

  def test_inspect
    assert_equal "(1, 2)", LambdaLifter::Pos.new(1, 2).inspect
  end

  def test_hash
    h = {}
    a = LambdaLifter::Pos.new(1, 2).hash
    b =  LambdaLifter::Pos.new(1, 2).hash
    h[a] = true
    h[b] = true
    assert_equal a.hash, b.hash
    assert_equal 1, h.keys.size
  end
end
