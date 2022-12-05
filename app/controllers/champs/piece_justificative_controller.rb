class Champs::PieceJustificativeController < ApplicationController
  before_action :authenticate_logged_user!
  before_action :set_champ

  def show
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_url) }
    end
  end

  def update
    if attach_piece_justificative_or_retry
      render :show
    else
      render json: { errors: @champ.errors.full_messages }, status: 422
    end
  end

  def template
    redirect_to @champ.type_de_champ.piece_justificative_template.blob
  end

  private

  def set_champ
    @champ = policy_scope(Champ).find(params[:champ_id])
  end

  def attach_piece_justificative
    @champ.piece_justificative_file.attach(params[:blob_signed_id])
    save_succeed = @champ.save
    @champ.dossier.update(last_champ_updated_at: Time.zone.now.utc) if save_succeed
    save_succeed
  end

  def attach_piece_justificative_or_retry
    attach_piece_justificative
  rescue ActiveRecord::StaleObjectError
    attach_piece_justificative
  end
end
