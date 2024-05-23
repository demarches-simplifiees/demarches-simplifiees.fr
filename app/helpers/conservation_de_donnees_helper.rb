module ConservationDeDonneesHelper
  def politiques_conservation_de_donnees(procedure)
    [conservation_dans_ds(procedure)].compact
  end

  private

  def conservation_dans_ds(procedure)
    if procedure.duree_conservation_dossiers_dans_ds.present?
      I18n.t('users.procedure_footer.legals.data_retention',
             application_name: Current.application_name,
             duree_conservation_dossiers_dans_ds: procedure.duree_conservation_dossiers_dans_ds)
    end
  end
end
