class Champs::PieceJustificativeController < ApplicationController
  before_action :authenticate_logged_user!

  def update
    if attach_piece_justificative_or_retry
      render :show
    else
      render json: { errors: @champ.errors.full_messages }, status: 422
    end
  end

  private

  def attach_piece_justificative
    @champ = policy_scope(Champ).find(params[:champ_id])
    @champ.piece_justificative_file.attach(params[:blob_signed_id])
    @champ.save
  end

  def attach_piece_justificative_or_retry
    attach_piece_justificative
  rescue ActiveRecord::StaleObjectError
    attach_piece_justificative
  end
end
