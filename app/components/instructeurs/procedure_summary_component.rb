# frozen_string_literal: true

class Instructeurs::ProcedureSummaryComponent < ApplicationComponent
  with_collection_parameter :procedure

  delegate :current_administrateur,
            :current_instructeur,
            :tags_summary_notification,
            :procedure_libelle_with_number,
            :procedure_badge,
            :number_with_html_delimiter,
    to: :helpers

  attr_reader :procedure,
              :dossiers_count_per_procedure,
              :dossiers_a_suivre_count_per_procedure,
              :dossiers_termines_count_per_procedure,
              :dossiers_expirant_count_per_procedure,
              :followed_dossiers_count_per_procedure,
              :procedure_ids_with_notifications,
              :notifications_counts_per_procedure

  alias_method :p, :procedure

  def initialize(procedure:,
    dossiers_count_per_procedure:,
    dossiers_a_suivre_count_per_procedure:,
    dossiers_termines_count_per_procedure:,
    dossiers_expirant_count_per_procedure:,
    followed_dossiers_count_per_procedure:,
    procedure_ids_with_notifications:,
    notifications_counts_per_procedure:,
    has_export_notification:)
    @procedure = procedure
    @dossiers_count_per_procedure = dossiers_count_per_procedure
    @dossiers_a_suivre_count_per_procedure = dossiers_a_suivre_count_per_procedure
    @dossiers_termines_count_per_procedure = dossiers_termines_count_per_procedure
    @dossiers_expirant_count_per_procedure = dossiers_expirant_count_per_procedure
    @followed_dossiers_count_per_procedure = followed_dossiers_count_per_procedure
    @procedure_ids_with_notifications = procedure_ids_with_notifications
    @notifications_counts_per_procedure = notifications_counts_per_procedure
    @has_export_notification = has_export_notification
  end

  def has_export_notification? = @has_export_notification
end
