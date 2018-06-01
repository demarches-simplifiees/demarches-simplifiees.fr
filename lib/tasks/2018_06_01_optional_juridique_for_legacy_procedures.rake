namespace :'2018_06_01_optional_juridique_for_legacy_procedures' do
  task set: :environment do
    Procedure.all.update_all(juridique_required: false)
  end
end
