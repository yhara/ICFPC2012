# -*- coding: utf-8 -*-
class LambdaLifter
  class TestLifter < Test::Unit::TestCase
    should "debug?は環境変数ENVがDEBUGだとtrueを返す" do
      ENV["DEBUG"] = "true"
      assert_equal true, LambdaLifter.debug?
    end

    should "loggerはdebug?がtrueだとlogdevがnilのloggerを返す" do
      ENV["DEBUG"] = "true"
      assert_equal true, LambdaLifter.debug?
      assert_nil LambdaLifter.logger.instance_variable_get(:@logdev)
    end
  end
end
