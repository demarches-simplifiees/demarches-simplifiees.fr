class Champs::RepetitionController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    @champs = @champ.add_row
  end
end
