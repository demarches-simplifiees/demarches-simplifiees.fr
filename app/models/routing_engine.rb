# frozen_string_literal: true

module RoutingEngine
  def self.compute(dossier, assignment_mode: DossierAssignment.modes.fetch(:auto))
    return if dossier.forced_groupe_instructeur

    matching_groupe = dossier.procedure.groupe_instructeurs.active.select(:routing_rule, :id, :procedure_id).find do |gi|
      gi.routing_rule&.compute(dossier.filled_champs)
    end

    matching_groupe = matching_groupe&.valid_rule? ? matching_groupe.reload : dossier.procedure.defaut_groupe_instructeur

    dossier.assign_to_groupe_instructeur(matching_groupe, assignment_mode)
  end
end
