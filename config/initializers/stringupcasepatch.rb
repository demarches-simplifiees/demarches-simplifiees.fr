require "unicode_utils/upcase"

class String

  def upcase
    UnicodeUtils.upcase(self)
  end

end
