# -*- coding: utf-8 -*-
class LambdaLifter
  # hashメソッドがあるクラスに対してeql?メソッドを定義するモジュール
  module HashEqlable
    def eql?(other)
      hash.eql?(other.hash)
    end

    def hash
      raise NotImplementedError
    end
  end
end
