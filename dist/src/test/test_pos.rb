class TestPos < Test::Unit::TestCase
  def test_pos
    pos = LambdaLifter::Pos.new(1, 1)
    assert_equal 1, pos.x
    assert_equal 1, pos.y
  end
end
