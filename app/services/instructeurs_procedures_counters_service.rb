# frozen_string_literal: true

class InstructeursProceduresCountersService
  Result = Data.define(
    :groupes_instructeurs_ids,
    :dossiers_count_per_procedure,
    :dossiers_a_suivre_count_per_procedure,
    :dossiers_termines_count_per_procedure,
    :dossiers_expirant_count_per_procedure,
    :followed_dossiers_count_per_procedure,
    :all_dossiers_counts
  )

  attr_reader :instructeur
  attr_reader :procedures

  def initialize(instructeur:, procedures:)
    @instructeur, @procedures = instructeur, procedures
  end

  def call
    groupes_instructeurs_ids = procedures
      .joins(:groupe_instructeurs)
      .distinct
      .pluck(GroupeInstructeur.arel_table[:id])

    dossiers = instructeur.dossiers
      .joins(:groupe_instructeur)
      .where(groupe_instructeur_id: groupes_instructeurs_ids)
      .group('groupe_instructeurs.procedure_id')
      .reorder(nil)

    dossiers_count_per_procedure = dossiers.by_statut('tous').count
    dossiers_a_suivre_count_per_procedure = dossiers.by_statut('a-suivre').count
    dossiers_termines_count_per_procedure = dossiers.by_statut('traites').count
    dossiers_expirant_count_per_procedure = dossiers.by_statut('expirant').count

    followed_dossiers_count_per_procedure = instructeur.followed_dossiers
      .joins(:groupe_instructeur)
      .en_cours
      .where(groupe_instructeur_id: groupes_instructeurs_ids)
      .visible_by_administration
      .group('groupe_instructeurs.procedure_id')
      .reorder(nil)
      .count

    all_dossiers_counts = {
      'a-suivre' => dossiers_a_suivre_count_per_procedure.values.sum,
      'suivis' => followed_dossiers_count_per_procedure.values.sum,
      'traites' => dossiers_termines_count_per_procedure.values.sum,
      'tous' => dossiers_count_per_procedure.values.sum,
      'expirant' => dossiers_expirant_count_per_procedure.values.sum,
    }

    Result.new(
      groupes_instructeurs_ids:,
      dossiers_count_per_procedure:,
      dossiers_a_suivre_count_per_procedure:,
      dossiers_termines_count_per_procedure:,
      dossiers_expirant_count_per_procedure:,
      followed_dossiers_count_per_procedure:,
      all_dossiers_counts:
    )
  end
end
