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

    purge_replaced_attachment

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

  def purge_replaced_attachment
    return if params[:replace_attachment_id].blank?

    attachment = @champ.piece_justificative_file.attachments.find { _1.id == params[:replace_attachment_id].to_i }
    attachment&.purge_later
  end
end
