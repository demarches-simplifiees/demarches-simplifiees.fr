class Champs::PieceJustificativeController < ApplicationController
  before_action :authenticate_logged_user!

  def update
    @champ = policy_scope(Champ).find(params[:champ_id])

    @champ.piece_justificative_file.attach(params[:blob_signed_id])
    if @champ.save
      render :show
    else
      errors = @champ.errors.full_messages
      render :json => { errors: errors }, :status => 422
    end
  end
end
