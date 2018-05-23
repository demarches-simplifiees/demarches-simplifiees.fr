module ProcedureFeatureSpecHelper
  def fill_in_dummy_procedure_details
    fill_in 'procedure_libelle', with: 'libelle de la procedure'
    page.execute_script("$('#procedure_description').val('description de la procedure')")
    fill_in 'procedure_duree_conservation_dossiers_dans_ds', with: '3'
    fill_in 'procedure_duree_conservation_dossiers_hors_ds', with: '6'
  end
end
