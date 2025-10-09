# frozen_string_literal: true

class Instructeurs::ProcedureSummaryComponent < ApplicationComponent
  with_collection_parameter :procedure

  delegate  :current_administrateur,
            :current_instructeur,
            :procedure_libelle_with_number,
            :procedure_badge,
            to: :helpers

  attr_reader :procedure

  alias_method :p, :procedure

  def initialize(procedure:,
    notifications_counts_per_procedure: {},
    has_export_notification: false)
    @procedure = procedure
    @has_export_notification = has_export_notification
  end

  def has_export_notification? = @has_export_notification

  def placeholder_span
    "⋯"
  end
end
