namespace :'2018_01_31_cast_untyped_champs' do
  task cast: :environment do
    champs = Champ.joins(:type_de_champ).where(typed: nil)
    # Cast only :yes_no, :checkbox and :engagement types.
    champs = champs.where(types_de_champ: { type_champ: [:yes_no, :checkbox, :engagement] })

    champs.find_each do |c|
      puts "Casting champ \"#{c.libelle}\" of type #{c.type_champ}"
      c.value = c.value
      c.save!
    end
  end
end
