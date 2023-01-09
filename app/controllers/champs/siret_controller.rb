class Champs::SiretController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])
    @siret = @champ.fetch_etablissement!(read_param_value(@champ.input_name, 'value'), current_user)
  end
end
