# frozen_string_literal: true

class Instructeurs::BulkMessageFormComponent < ApplicationComponent
  attr_reader :current_instructeur, :procedure, :dossiers_count_per_groupe_instructeur

  def initialize(current_instructeur:, procedure:, dossiers_count_per_groupe_instructeur:)
    @current_instructeur = current_instructeur
    @procedure = procedure
    @dossiers_count_per_groupe_instructeur = dossiers_count_per_groupe_instructeur
  end

  def default_dossiers_count
    if procedure.routing_enabled
      @dossiers_count_per_groupe_instructeur.sum do |groupe_instructeur_id, dossier_count|
        if instructeur_in_all_groupes? || current_instructeur_in_groupe?(groupe_instructeur_id)
          dossier_count
        else
          0
        end
      end
    else
      @dossiers_count_per_groupe_instructeur.values.sum
    end
  end

  def instructeur_in_all_groupes? = @in_all_groupes ||= procedure.groupe_instructeurs.size == instructeur_groupe_ids.size

  private

  def current_instructeur_in_groupe?(groupe_instructeur_id) = groupe_instructeur_id.in?(instructeur_groupe_ids)

  def instructeur_groupe_ids
    @instructeur_groupe_ids ||= current_instructeur
      .groupe_instructeurs
      .filter { _1.procedure_id == procedure.id }
      .map(&:id)
  end
end
