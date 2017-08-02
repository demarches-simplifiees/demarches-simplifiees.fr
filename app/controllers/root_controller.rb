class RootController < ApplicationController
  layout 'new_application'

  def index
    if administrateur_signed_in?
      return redirect_to admin_procedures_path

    elsif gestionnaire_signed_in?
      return redirect_to backoffice_invitations_path if current_gestionnaire.avis.any?

      procedure_id = current_gestionnaire.procedure_filter
      if procedure_id.nil?
        procedure_list = current_gestionnaire.procedures

        if procedure_list.count > 0
          return redirect_to backoffice_dossiers_procedure_path(id: procedure_list.first.id)
        else
          flash.alert = "Vous n'avez aucune procédure d'affectée"
        end
      else
        return redirect_to backoffice_dossiers_procedure_path(id: procedure_id)
      end

    elsif user_signed_in?
      return redirect_to users_dossiers_path

    elsif administration_signed_in?
      return redirect_to administrations_path
    end

    render 'landing'
  end

  def patron
    description = 'a not so long description'

    all_champs = TypeDeChamp.type_champs
      .map { |name, _| TypeDeChamp.new(type_champ: name, libelle: name, description: description, mandatory: true) }
      .map { |type_de_champ| ChampPublic.new(type_de_champ: type_de_champ) }
      .map.with_index do |champ, i|
        champ.id = i
        champ
      end

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
      'textarea': 'Une description de mon projet',
      'explication': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In erat mauris, faucibus quis pharetra sit amet, pretium ac libero. Etiam vehicula eleifend bibendum. Morbi gravida metus ut sapien condimentum sodales mollis augue sodales. Vestibulum quis quam at sem placerat aliquet',
    }

    type_champ_values.each do |(type_champ, value)|
      all_champs
        .select { |champ| champ.type_champ == type_champ.to_s }
        .each { |champ| champ.value = value }
    end

    @dossier = Dossier.new(champs: all_champs)
  end
end
