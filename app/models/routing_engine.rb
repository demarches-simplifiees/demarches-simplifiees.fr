module RoutingEngine
  def self.compute(dossier)
    return if !dossier.procedure.feature_enabled?(:routing_rules)
    return if dossier.forced_groupe_instructeur

    matching_groupe = dossier.procedure.groupe_instructeurs.active.find do |gi|
      gi.routing_rule&.compute(dossier.champs)
    end
    matching_groupe ||= dossier.procedure.defaut_groupe_instructeur
    dossier.assign_to_groupe_instructeur(matching_groupe)
  end
end
