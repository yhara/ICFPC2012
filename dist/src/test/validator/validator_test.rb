# -*- coding: utf-8 -*-
class LambdaLifter
  class ValidatorTest < Test::Unit::TestCase
    private

    def treat_actual_map(s)
      s = strip_line_end(s)
      # Validatorは:winning時にOだがMineはクリア時はRなのでその補正
      s = s.sub("R", "O") if !/[LO]/.match(s)
      # Validatorは各トランポリンごとの違いを区別しない
      s = s.gsub(/[A-I]/, "T").gsub(/[1-9]/, "t")
      return s
    end

    def treat_expected_map(s)
      s = strip_line_end(s)
      return s
    end

    def strip_line_end(s)
      return s.split("\n").map(&:rstrip).join("\n")
    end
  end
end
