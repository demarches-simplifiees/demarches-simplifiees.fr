class Champs::PieceJustificativeController < Champs::ChampController
  def show
    # pf used to redirect to this route to download PJ ==> if param h is present (old pf link) then redirect to new route
    return redirect_to download_path if params[:h].present?

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_url) }
    end
  end

  def download_path
    if params[:dossier_id].present?
      champs_piece_justificative_download_path({ dossier_id: params[:dossier_id], stable_id: params[:stable_id], row_id: params[:row_id], h: params[:h], i: "0" })
    else
      champs_legacy_piece_justificative_download_path({ champ_id: params[:champ_id], h: params[:h], i: "0" })
    end
  end

  def update
    if attach_piece_justificative
      render :show
    else
      render json: { errors: @champ.errors.full_messages }, status: 422
    end
  end

  def download
    if @champ&.is_a? Champs::PieceJustificativeChamp
      index = (params[:i] || "0").to_i
      if (0..@champ.piece_justificative_file.size).cover?(index)
        blob = @champ.piece_justificative_file[index]
        if blob.filename.extension == 'pdf' && @champ.dossier.procedure.feature_enabled?(:qrcoded_pdf)
          send_data StampService.new.stamp(blob, TypesDeChamp::PieceJustificativeTypeDeChamp.download_url(@champ, index)), filename: blob.filename.to_s, type: 'application/pdf'
        else
          redirect_to blob.url, status: :found, allow_other_host: true
        end
      else
        flash.alert = "Le document demandé n'existe pas."
        redirect_to :root, status: :bad_request
      end
    else
      flash.alert = "Le document demandé n'existe pas ou vous n'avez pas l'autorisation d'y accéder."
      redirect_to :root, status: :bad_request
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
      save_succeed = @champ.save
    end

    if @champ.private?
      ChampRevision.create_or_update_revision(@champ, current_instructeur.id)
    end

    @champ.dossier.update(last_champ_updated_at: Time.zone.now.utc) if save_succeed

    save_succeed
  end

  def find_champ
    h = params[:h]
    return super if h.blank?

    champ = if params[:champ_id].present?
      Champ.find(params[:champ_id])
    else
      dossier = Dossier.includes(:champs, revision: [:types_de_champ]).find(params[:dossier_id])
      type_de_champ = dossier.find_type_de_champ_by_stable_id(params[:stable_id])
      dossier.champ_for_export(type_de_champ, params_row_id)
    end
    champ&.match_encoded_date?(:created_at, h) ? champ : nil
  end
end
