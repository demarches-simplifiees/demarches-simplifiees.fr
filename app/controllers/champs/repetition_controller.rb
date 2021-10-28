class Champs::RepetitionController < ApplicationController
  before_action :authenticate_logged_user!

  def show
    @champ = policy_scope(Champ).includes(:champs).find(params[:champ_id])
    @position = params[:position]
    @champ.add_row

    if @champ.private?
      @attribute = "dossier[champs_private_attributes][#{@position}][champs_attributes]"
    else
      @attribute = "dossier[champs_attributes][#{@position}][champs_attributes]"
    end
  end
end
