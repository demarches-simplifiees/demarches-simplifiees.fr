# frozen_string_literal: true

class Procedure::Card::AiComponent < ApplicationComponent
  delegate :score, to: :linter
  delegate :rate, to: :linter
  delegate :perfect_rate?, to: :linter

  attr_reader :procedure

  def initialize(procedure:)
    @procedure = procedure
  end

  def linter
    @linter = ProcedureLinter.new(procedure, procedure.draft_revision)
  end

  def render?
    rate_ok?
  end

  def rate
    "#{@linter.rate} / #{@linter.top_rate}"
  end

  def errors_count
    @linter.score
  end

  def rate_ok?
    perfect_rate?.inspect
  end
end
