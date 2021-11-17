module ConservationDeDonneesHelper
  def politiques_conservation_de_donnees(procedure)
    [conservation_dans_ds(procedure)].compact
  end

  private

  def conservation_dans_ds(procedure)
    if procedure.duree_conservation_dossiers_dans_ds.present?
      "Dans #{APPLICATION_NAME} : #{procedure.duree_conservation_dossiers_dans_ds} mois"
    end
  end
end
