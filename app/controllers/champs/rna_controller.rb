class Champs::RNAController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])
    @rna = read_param_value(@champ.input_name, 'value')
    @network_error = @champ.fetch_association!(@rna).present?
  end
end
