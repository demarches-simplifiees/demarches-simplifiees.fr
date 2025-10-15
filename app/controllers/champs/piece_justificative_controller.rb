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
    redirect_to rails_blob_url(@champ.type_de_champ.piece_justificative_template.blob, disposition: 'attachment')
  end

  private

  def attach_piece_justificative
    save_succeed = nil

    ActiveStorage::Attachment.transaction do
      @champ.piece_justificative_file.attach(params[:blob_signed_id])
      context = @champ.public? ? :champs_public_value : :champs_private_value
      save_succeed = @champ.save(context:)
    end

    if save_succeed
      @champ.fetch_later! if @champ.uses_external_data?

      @champ.update_timestamps

      dossier = DossierPreloader.load_one(@champ.dossier, pj_template: true)
      # because preloader reassigns new champ instances champs, we have to reassign it
      @champ = dossier.champs.find { it.id == @champ.id }
    end

    save_succeed
  end
end
