module RoutingEngine
  def self.compute(dossier)
    return if dossier.forced_groupe_instructeur

    previous_groupe_instructeur = dossier.groupe_instructeur

    matching_groupe = dossier.procedure.groupe_instructeurs.active.reject(&:invalid_rule?).find do |gi|
      gi.routing_rule&.compute(dossier.champs)
    end

    matching_groupe ||= dossier.procedure.defaut_groupe_instructeur

    dossier.assign_to_groupe_instructeur(matching_groupe)

    DossierAssignment.create!(
      dossier_id: dossier.id,
      mode: 'auto',
      previous_groupe_instructeur_id: previous_groupe_instructeur&.id,
      groupe_instructeur_id: matching_groupe.id,
      previous_groupe_instructeur_label: previous_groupe_instructeur&.label,
      groupe_instructeur_label: matching_groupe.label,
      assigned_at: Time.zone.now
    )
  end
end
