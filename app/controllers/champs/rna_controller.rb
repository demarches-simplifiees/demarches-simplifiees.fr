class Champs::RNAController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])
    rna = read_param_value(@champ.input_name, 'value')

    unless @champ.fetch_association!(rna)
      @error = @champ.association_fetch_error_key
    end
  end
end
