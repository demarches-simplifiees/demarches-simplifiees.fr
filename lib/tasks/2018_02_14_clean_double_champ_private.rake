namespace :'2018_02_14_clean_double_champ_private' do
  task clean: :environment do
    Champ.where(private: true).group_by(&:dossier_id).each_value do |champs|
      seen = []
      champs.each do |champ|
        if champ.type_de_champ_id.in?(seen)
          champ.destroy
        else
          seen << champ.type_de_champ_id
        end
      end
    end
  end
end
