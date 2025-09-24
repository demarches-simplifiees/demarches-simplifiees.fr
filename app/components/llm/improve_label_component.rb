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

  def changes_json
    { update: change_items.map { |item| serialized_update(item) } }.to_json
  end

  def update_items
    change_items
  end

  def tdc_for(stable_id)
    tdc_by_stable_id[stable_id]
  end

  def rule
    TOOL_NAME
  end

  private

  def serialized_update(item)
    payload = item.payload || {}

    {
      stable_id: item.stable_id,
      libelle: payload['libelle'],
      type_champ: payload['type_champ'],
      justification: item.justification,
      confidence: item.confidence
    }.compact
  end
end
