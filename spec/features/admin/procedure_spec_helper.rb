module ProcedureSpecHelper
  def fill_in_dummy_procedure_details
    fill_in 'procedure_libelle', with: 'libelle de la procedure'
    page.execute_script("$('#procedure_description').val('description de la procedure')")
    fill_in 'procedure_cadre_juridique', with: 'cadre juridique'
  end
end
