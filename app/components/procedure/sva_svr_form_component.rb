# frozen_string_literal: true

class Procedure::SVASVRFormComponent < ApplicationComponent
  attr_reader :procedure, :configuration

  def initialize(procedure:, configuration:)
    @procedure = procedure
    @configuration = configuration
  end

  def form_disabled?
    return false if procedure.brouillon?
    return true if !procedure.feature_enabled?(:sva)

    procedure.sva_svr_enabled?
  end

  def decision_buttons
    scope = ".decision_buttons"

    [
      { label: t("disabled", scope:), value: "disabled", disabled: form_disabled? },
      { label: t("sva", scope:), value: "sva", hint: t("sva_hint", scope:) },
      { label: t("svr", scope:), value: "svr", hint: t("svr_hint", scope:) }
    ]
  end

  def resume_buttons
    scope = ".resume_buttons"

    [
      {
        value: "continue",
        label: t("continue_label", scope: scope),
        hint: t("continue_hint", scope: scope)
      },
      {
        value: "reset",
        label: t("reset_label", scope: scope),
        hint: t("reset_hint", scope: scope)
      }
    ]
  end
end
