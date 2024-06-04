module RoutingEngine
  def self.compute(dossier, assignment_mode: DossierAssignment.modes.fetch(:auto))
    return if dossier.forced_groupe_instructeur

    matching_groupe = dossier.procedure.groupe_instructeurs.active.reject(&:invalid_rule?).find do |gi|
      gi.routing_rule&.compute(dossier.champs)
    end

    matching_groupe ||= dossier.procedure.defaut_groupe_instructeur

    dossier.assign_to_groupe_instructeur(matching_groupe, assignment_mode)
  end
end
