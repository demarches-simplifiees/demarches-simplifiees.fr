class Champs::DossierLinkController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).find(params[:champ_id])
    @linked_dossier_id = read_param_value(@champ.input_name, 'value')
  end
end
