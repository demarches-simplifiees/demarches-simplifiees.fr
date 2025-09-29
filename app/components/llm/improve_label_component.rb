# frozen_string_literal: true

class LLM::ImproveLabelComponent < ApplicationComponent
  TOOL_NAME = LLM::LabelImprover::TOOL_NAME

  attr_reader :revision, :change_items, :tdcs, :tdc_by_stable_id

  def initialize(changes:, revision:)
    @revision = revision
    @change_items = Array(changes['update'])
    @tdcs = revision.types_de_champ_public
    @tdc_by_stable_id = @tdcs.index_by(&:stable_id)
  end

  def procedure
    @procedure ||= revision.procedure
  end

  private
end
