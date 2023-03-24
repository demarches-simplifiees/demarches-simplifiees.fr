module RoutingEngine
  def self.compute(dossier)
    matching_groupe = dossier.procedure.groupe_instructeurs.find do |gi|
      gi.routing.compute(dossier.champs)
    end
    if matching_groupe
      dossier.update!(groupe_instructeur: matching_groupe)
    else
      dossier.update!(groupe_instructeur: dossier.procedure.defaut_groupe_instructeur)
    end
  end
end
