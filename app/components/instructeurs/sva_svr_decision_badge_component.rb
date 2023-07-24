# frozen_string_literal: true

class Instructeurs::SVASVRDecisionBadgeComponent < ApplicationComponent
  attr_reader :object
  attr_reader :procedure
  attr_reader :with_label

  def initialize(projection_or_dossier:, procedure:, with_label: false)
    @object = projection_or_dossier
    @procedure = procedure
    @decision = procedure.sva_svr_configuration.decision.to_sym
    @with_label = with_label
  end

  def render?
    return false unless procedure.sva_svr_enabled?

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

  def label_for_badge
    sva? ? "SVA :" : "SVR :"
  end

  def title
    return if without_date?

    if pending_correction?
      t(".dossier_terminated_x_days_after_correction", count: days_count)
    else
      t(".dossier_terminated_on", date: helpers.l(object.sva_svr_decision_on))
    end
  end
end
