# frozen_string_literal: true

class Instructeurs::ProcedureCountersComponent < ApplicationComponent
  with_collection_parameter :procedure

  delegate :turbo_stream, :current_instructeur, :number_with_html_delimiter, :tags_summary_notification, to: :helpers

  attr_reader :procedure, :notifications_counts_per_procedure

  def initialize(procedure:, counters:, notifications_counts_per_procedure:, procedure_ids_with_notifications:)
    @procedure = procedure
    @counters = counters
    @notifications_counts_per_procedure = notifications_counts_per_procedure
    @procedure_ids_with_notifications = procedure_ids_with_notifications
  end

  def a_suivre_count
    formatted_count(:dossiers_a_suivre_count_per_procedure)
  end

  def followed_count
    formatted_count(:followed_dossiers_count_per_procedure)
  end

  def termines_count
    formatted_count(:dossiers_termines_count_per_procedure)
  end

  def dossier_count
    formatted_count(:dossiers_count_per_procedure)
  end

  def expirant_count
    formatted_count(:dossiers_expirant_count_per_procedure)
  end

  def notifications?
    current_instructeur.feature_enabled?(:notification) &&
      @notifications_counts_per_procedure[procedure.id]&.any?
  end

  def each_statut_having_notification
    [:suivis, :a_suivre, :traites].each do |statut|
      if @procedure_ids_with_notifications[statut].include?(procedure.id)
        yield statut
      end
    end
  end

  private

  def formatted_count(method_name)
    count = @counters.public_send(method_name).fetch(procedure.id, 0)
    number_with_html_delimiter(count)
  end
end
