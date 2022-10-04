class Champs::RNAController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])
    @rna = read_param_value(@champ.input_name, 'value')
    begin
      data = APIEntreprise::RNAAdapter.new(@rna, @champ.procedure_id).to_params
      @champ.update(data: data, value: @rna, skip_cleanup: true, skip_fetch: true)
    rescue => error
      @champ.update(data: nil, value: @rna, skip_cleanup: true, skip_fetch: true)
    end
  end
end
