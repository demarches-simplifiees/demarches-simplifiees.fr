namespace :'2017_09_19_set_confidentialite_to_old_avis' do
  task set: :environment do
    Avis.unscope(:joins).update_all(confidentiel: true)
  end
end
