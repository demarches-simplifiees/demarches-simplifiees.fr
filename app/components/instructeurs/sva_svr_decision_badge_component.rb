# frozen_string_literal: true

class Instructeurs::SVASVRDecisionBadgeComponent < ApplicationComponent
  attr_reader :object

  def initialize(projection_or_dossier:, decision:)
    @object = projection_or_dossier
    @decision = decision.to_sym
  end

  def render?
    [:en_construction, :en_instruction].include? object.state.to_sym
  end

  def without_date?
    object.sva_svr_decision_on.nil?
  end

  def classes
    class_names(
      'fr-badge fr-badge--sm': true,
      'fr-badge--warning': soon?,
      'fr-badge--info': !soon?
    )
  end

  def soon?
    object.sva_svr_decision_on < 7.days.from_now.to_date
  end

  def pending_correction?
    object.pending_correction?
  end

  def days_count
    (object.sva_svr_decision_on - Date.current).to_i
  end

  def sva?
    @decision == :sva
  end

  def svr?
    @decision == :svr
  end
end
