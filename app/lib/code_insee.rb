# frozen_string_literal: true

class CodeInsee
  def initialize(code_insee)
    @code_insee = code_insee
  end

  def to_departement
    dept = @code_insee.strip.first(2)
    if dept < "97"
      dept
    else
      @code_insee.strip.first(3)
    end
  end
end
