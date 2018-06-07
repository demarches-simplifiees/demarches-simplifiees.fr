namespace :'2018_05_24_optional_durees_conservation_for_legacy_procedures' do
  task set: :environment do
    Procedure.all.update_all(durees_conservation_required: false)
  end
end
