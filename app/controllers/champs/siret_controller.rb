class Champs::SiretController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])
    @siret = read_param_value(@champ.input_name, 'value')
    @etablissement = @champ.etablissement

    if @siret.empty?
      return clear_siret_and_etablissement
    end

    if !Siret.new(siret: @siret).valid?
      # i18n-tasks-use t('errors.messages.invalid_siret')
      return siret_error(:invalid)
    end

    begin
      etablissement = find_etablissement_with_siret
    rescue APIEntreprise::API::Error::RequestFailed, APIEntreprise::API::Error::BadGateway, APIEntreprise::API::Error::TimedOut, APIEntreprise::API::Error::ServiceUnavailable, APIEntrepriseToken::TokenError
      # i18n-tasks-use t('errors.messages.siret_network_error')
      return siret_error(:network_error)
    end
    if etablissement.nil?
      # i18n-tasks-use t('errors.messages.siret_not_found')
      return siret_error(:not_found)
    end

    @etablissement = etablissement
    if !@champ.nil?
      @champ.update!(value: etablissement.siret, etablissement: etablissement)
    end
  end

  private

  def find_etablissement_with_siret
    APIEntrepriseService.create_etablissement(@champ, @siret, current_user.id)
  end

  def clear_siret_and_etablissement
    @champ.update!(value: '')
    @etablissement&.destroy
  end

  def siret_error(error)
    clear_siret_and_etablissement
    @siret = error
  end
end
