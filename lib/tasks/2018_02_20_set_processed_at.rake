namespace :'2018_02_20_set_processed_at' do
  task set: :environment do
    Dossier.where(state: :accepte, processed_at: nil).find_each do |dossier|
      dossier.update_column(:processed_at, dossier.en_instruction_at)
    end
  end
end
