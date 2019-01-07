class RootController < ApplicationController
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

  def administration
  end

  def patron
    description = 'aller voir le super site : https://demarches-simplifiees.fr'

    all_champs = TypeDeChamp.type_champs
      .map { |name, _| TypeDeChamp.new(type_champ: name, private: false, libelle: name, description: description, mandatory: true) }
      .map.with_index { |type_de_champ, i| type_de_champ.champ.build(id: i) }

    all_champs
      .select { |champ| champ.type_champ == TypeDeChamp.type_champs.fetch(:header_section) }
      .each { |champ| champ.type_de_champ.libelle = 'un super titre de section' }

    all_champs
      .select { |champ| [TypeDeChamp.type_champs.fetch(:drop_down_list), TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)].include?(champ.type_champ) }
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
      TypeDeChamp.type_champs.fetch(:date)      => '2016-07-26',
      TypeDeChamp.type_champs.fetch(:datetime)  => '26/07/2016 07:35',
      TypeDeChamp.type_champs.fetch(:textarea)  => 'Une description de mon projet'
    }

    type_champ_values.each do |(type_champ, value)|
      all_champs
        .select { |champ| champ.type_champ == type_champ }
        .each { |champ| champ.value = value }
    end

    @dossier = Dossier.new(champs: all_champs)
  end

  def accessibilite
  end

  def suivi
  end

  def tour_de_france
  end
end
