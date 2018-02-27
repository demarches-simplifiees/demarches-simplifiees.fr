namespace :'2018_02_13_fill_champ_private_and_type' do
  task set: :environment do
    Champ.includes(:type_de_champ).find_each do |champ|
      if champ.type_de_champ.present?
        champ.update_columns(champ.type_de_champ.params_for_champ)
      end
    end

    TypeDeChamp.find_each do |type_de_champ|
      type_de_champ.update_columns(
        private: type_de_champ.private?,
        type: TypeDeChamp.type_champ_to_class_name(type_de_champ.type_champ)
      )
    end
  end
end
