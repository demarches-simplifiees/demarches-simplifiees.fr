class Champs::PieceJustificativeController < ApplicationController
  before_action :authenticate_logged_user!
  before_action :set_champ

  def show
    # pf used to redirect to this route to download PJ ==> if param h is present (old pf link) then redirect to new route
    return redirect_to champs_piece_justificative_download_path(params) if params[:h].present?

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

  def download
    champ = find_champ

    if champ&.is_a? Champs::PieceJustificativeChamp
      blob = champ.piece_justificative_file
      if blob.filename.extension == 'pdf' && champ.dossier.procedure.feature_enabled?(:qrcoded_pdf)
        url = Rails.application.routes.url_helpers.champs_piece_justificative_download_url(
          { champ_id: champ.id, h: champ.encoded_date(:created_at) }
        )
        send_data StampService.new.stamp(blob, url), filename: blob.filename.to_s, type: 'application/pdf'
      else
        redirect_to blob.service_url, status: :found
      end
    else
      flash.alert = "Le document demandé n'existe pas ou vous n'avez pas l'autorisation d'y accéder."
      redirect_to :root, status: :bad_request
    end
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

  def find_champ
    h = params[:h]
    return if h.blank?

    champ = Champ.find(params[:champ_id])
    champ&.match_encoded_date?(:created_at, h) ? champ : nil
  end
end
