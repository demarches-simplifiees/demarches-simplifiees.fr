class Champs::SiretController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @position = params[:position]
    extract_siret
    find_etablisement

    if @siret.empty?
      @champ&.update!(value: '')
      @etablissement&.destroy
    elsif @siret.present? && @siret.length == 14
      etablissement = find_etablisement_with_siret
      if etablissement.present?
        @etablissement = etablissement

        if !@champ.nil?
          @champ.update!(value: etablissement.siret, etablissement: etablissement)
        end
      else
        @champ&.update!(value: '')
        @etablissement&.destroy
        @siret = :not_found
      end
    else
      @champ&.update!(value: '')
      @etablissement&.destroy
      @siret = :invalid
    end
  end

  private

  def extract_siret
    if params[:dossier].key?(:champs_attributes)
      @siret = params[:dossier][:champs_attributes][@position][:value]
      @attribute = "dossier[champs_attributes][#{@position}][etablissement_attributes]"
    else
      @siret = params[:dossier][:champs_private_attributes][@position][:value]
      @attribute = "dossier[champs_private_attributes][#{@position}][etablissement_attributes]"
    end
  end

  def find_etablisement
    if params[:champ_id].present?
      @champ = Champ.find_by(dossier_id: logged_user.dossiers, id: params[:champ_id])
      @etablissement = @champ&.etablissement
    end
    @procedure_id = @champ&.dossier&.procedure_id || 'aperçu'
  end

  def find_etablisement_with_siret
    etablissement_attributes = ApiEntrepriseService.get_etablissement_params_for_siret(@siret, @procedure_id)
    if etablissement_attributes.present?
      Etablissement.new(etablissement_attributes)
    end
  end
end
