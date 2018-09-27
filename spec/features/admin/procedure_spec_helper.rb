module ProcedureSpecHelper
  def fill_in_dummy_procedure_details(fill_path: true)
    fill_in 'procedure_libelle', with: 'libelle de la procedure'
    fill_in 'procedure_description', with: 'description de la procedure'
    if fill_path
      fill_in 'procedure_path', with: 'lien-de-la-procedure'
    end
    fill_in 'procedure_cadre_juridique', with: 'cadre juridique'
    fill_in 'procedure_duree_conservation_dossiers_dans_ds', with: '3'
    fill_in 'procedure_duree_conservation_dossiers_hors_ds', with: '6'
  end
end
