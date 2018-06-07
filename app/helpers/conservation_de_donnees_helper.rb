module ConservationDeDonneesHelper
  def politiques_conservation_de_donnees(procedure)
    [conservation_dans_ds(procedure), conservation_hors_ds(procedure)].compact
  end

  private

  def conservation_dans_ds(procedure)
    if procedure.duree_conservation_dossiers_dans_ds.present?
      "dans demarches-simplifiees.fr #{procedure.duree_conservation_dossiers_dans_ds} mois après le début de l’instruction du dossier"
    end
  end

  def conservation_hors_ds(procedure)
    if procedure.duree_conservation_dossiers_hors_ds.present?
      "hors demarches-simplifiees.fr pendant #{procedure.duree_conservation_dossiers_hors_ds} mois"
    end
  end
end
