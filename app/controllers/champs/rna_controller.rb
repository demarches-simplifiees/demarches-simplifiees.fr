class Champs::RNAController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])
    @error = @champ.association_fetch_error_key unless @champ.fetch_association!(read_param_value(@champ.input_name, 'value'))
  end
end
