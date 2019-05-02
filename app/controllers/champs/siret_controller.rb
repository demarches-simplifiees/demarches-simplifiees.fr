class Champs::SiretController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @position = params[:position]
    extract_siret
    find_etablisement

    if @siret.empty?
      return clear_siret_and_etablissement
    end

    if @siret.present? && @siret.length != 14
      return siret_error(:invalid)
    end

    begin
      etablissement = find_etablissement_with_siret
    rescue RestClient::RequestFailed
      return siret_error(:network_error)
    end
    if etablissement.blank?
      return siret_error(:not_found)
    end

    @etablissement = etablissement
    if !@champ.nil?
      @champ.update!(value: etablissement.siret, etablissement: etablissement)
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

  def find_etablissement_with_siret
    etablissement_attributes = ApiEntrepriseService.get_etablissement_params_for_siret(@siret, @procedure_id)
    if etablissement_attributes.present?
      Etablissement.new(etablissement_attributes)
    end
  end

  def clear_siret_and_etablissement
    @champ&.update!(value: '')
    @etablissement&.destroy
  end

  def siret_error(error)
    clear_siret_and_etablissement
    @siret = error
  end
end
