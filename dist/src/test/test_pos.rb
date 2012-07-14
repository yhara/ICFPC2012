# coding: utf-8

class TestPos < Test::Unit::TestCase
  should ".x, .yでアクセスできること" do
    pos = LambdaLifter::Pos.new(1, 1)
    assert_equal 1, pos.x
    assert_equal 1, pos.y
  end
end
