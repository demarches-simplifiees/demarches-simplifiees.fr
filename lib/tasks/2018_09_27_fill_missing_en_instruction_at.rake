namespace :'2018_09_27_fill_missing_en_instruction_at' do
  task run: :environment do
    dossiers_with_missing_instruction_at = Dossier
      .where.not(processed_at: nil)
      .where(en_instruction_at: nil)

    dossiers_with_missing_instruction_at.each { |d| d.update(en_instruction_at: d.processed_at) }
  end
end
