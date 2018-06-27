class RootController < ApplicationController
  layout 'new_application'

  def index
    if administrateur_signed_in?
      return redirect_to admin_procedures_path
    elsif gestionnaire_signed_in?
      return redirect_to gestionnaire_procedures_path
    elsif user_signed_in?
      return redirect_to dossiers_path
    elsif administration_signed_in?
      return redirect_to manager_root_path
    end

    render 'landing'
  end

  def patron
    description = 'aller voir le super site : https://demarches-simplifiees.fr'

    all_champs = TypeDeChamp.type_champs
      .map { |name, _| TypeDeChamp.new(type_champ: name, private: false, libelle: name, description: description, mandatory: true) }
      .map.with_index { |type_de_champ, i| type_de_champ.champ.build(id: i) }

    all_champs
      .select { |champ| champ.type_champ == 'header_section' }
      .each { |champ| champ.type_de_champ.libelle = 'un super titre de section' }

    all_champs
      .select { |champ| %w(drop_down_list multiple_drop_down_list).include?(champ.type_champ) }
      .each do |champ|
        champ.type_de_champ.drop_down_list = DropDownList.new(type_de_champ: champ.type_de_champ)
        champ.drop_down_list.value =
          "option A
          option B
          -- avant l'option C --
          option C"
        champ.value = '["option B", "option C"]'
      end

    type_champ_values = {
      'date': '2016-07-26',
      'datetime': '26/07/2016 07:35',
      'textarea': 'Une description de mon projet'
    }

    type_champ_values.each do |(type_champ, value)|
      all_champs
        .select { |champ| champ.type_champ == type_champ.to_s }
        .each { |champ| champ.value = value }
    end

    @dossier = Dossier.new(champs: all_champs)
  end
end
