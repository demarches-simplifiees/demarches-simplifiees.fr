class Champs::OptionsController < ApplicationController
  before_action :authenticate_logged_user!

  def remove
    @champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    @next_checkbox_id = @champ.next_checkbox_id(params[:option])
    @champ.remove_option([params[:option]].compact)
  end
end
