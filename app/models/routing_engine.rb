module RoutingEngine
  def self.compute(dossier)
    matching_groupe = dossier.procedure.groupe_instructeurs.active.find do |gi|
      gi.routing_rule&.compute(dossier.champs)
    end
    matching_groupe ||= dossier.procedure.defaut_groupe_instructeur
    dossier.update!(groupe_instructeur: matching_groupe)
  end
end
