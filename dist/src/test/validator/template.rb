# -*- coding: utf-8 -*-

=begin
generated at %{generate_time}

%{initial_map}

|
| %{commands}
v

%{processed_map}
score: %{score}
=end

class LambdaLifter
  class %{test_name} < Test::Unit::TestCase
    should "Validatorと同じ結果になる" do
      mine = Mine.new(<<EOS)
%{initial_map}
EOS
      "%{commands}".each_char do |s|
        mine.step!(s)
      end
      assert_equal <<EOS, mine.ascii_map
%{processed_map}
EOS
      assert_equal %{score}, mine.score
    end
  end
end
