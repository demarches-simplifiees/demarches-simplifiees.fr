class Champs::SiretController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])

    if @champ.fetch_etablissement!(read_param_value(@champ.input_name, 'value'), current_user)
      @siret = @champ.etablissement.siret
    else
      @siret = @champ.etablissement_fetch_error_key
    end
  end
end
