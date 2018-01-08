namespace :'2018_01_11_add_active_state_to_administrators' do
  task set: :environment do
    Administrateur.find_each do |administrateur|
      administrateur.update_column(:active, true)
    end
  end
end
