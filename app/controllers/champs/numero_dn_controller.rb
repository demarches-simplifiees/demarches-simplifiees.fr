class Champs::NumeroDnController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    set_dn_ddn
    if @dn !~ /\d{6,7}/
      return @status = :bad_dn_format
    end
    begin
      @ddn = Date.parse(@ddn)
    rescue
      return @status = :bad_ddn_format
    end
    check_dn
  end

  private

  def set_dn_ddn
    if params[:champ_id].present?
      @champ = policy_scope(Champ).find(params[:champ_id])
    end
    dossier    = params[:dossier]
    attributes = dossier.key?(:champs_attributes) ? :champs_attributes : champs_private_attributes
    @position  = params[:position]
    champ      = dossier[attributes][@position]
    @ddn       = champ[:date_de_naissance] || params[:ddn] || @champ&.date_de_naissance
    @dn        = champ[:numero_dn] || params[:dn] || @champ&.numero_dn
    @champ&.update(numero_dn: @dn, date_de_naissance: @ddn)
  end

  def check_dn
    result = ApiCPS::API.new().verify({ @dn => @ddn })
    case result[@dn]
    when 'true'
      @status = :good_dn
    when 'false'
      @status = :bad_ddn
    else
      @status = :bad_dn
    end
  rescue ApiEntreprise::API::RequestFailed
    @status = :network_error
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
