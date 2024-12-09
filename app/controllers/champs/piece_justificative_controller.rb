# frozen_string_literal: true

class Champs::PieceJustificativeController < Champs::ChampController
  def show
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_url) }
    end
  end

  def update
    if attach_piece_justificative
      render :show
    else
      render json: { errors: @champ.errors.full_messages }, status: 422
    end
  end

  def template
    redirect_to @champ.type_de_champ.piece_justificative_template.blob
  end

  private

  def attach_piece_justificative
    save_succeed = nil

    ActiveStorage::Attachment.transaction do
      @champ.piece_justificative_file.attach(params[:blob_signed_id])
      context = @champ.public? ? :champs_public_value : :champs_private_value
      save_succeed = @champ.save(context:)
    end

    if save_succeed && dossier.brouillon?
      dossier.touch(:last_champ_updated_at, :last_champ_piece_jointe_updated_at)
    end

    save_succeed
  end

  def dossier
    @champ.dossier
  end
end
