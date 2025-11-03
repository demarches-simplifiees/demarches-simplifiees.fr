# frozen_string_literal: true

class RetryableFetchError < StandardError
  attr_reader :cause

  def initialize(cause)
    @cause = cause
  end
end
