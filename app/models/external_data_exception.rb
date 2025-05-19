# frozen_string_literal: true

class ExternalDataException
  attr_accessor :reason, :code

  def initialize(reason:, code:)
    @reason = reason
    @code = code
  end
end
