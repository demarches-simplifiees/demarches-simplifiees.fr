class API::Public::V1::DossiersController < API::Public::V1::BaseController
  before_action :check_procedure_id_presence
  before_action :retreive_procedure

  def create
    dossier = Dossier.new(
      revision: @procedure.brouillon? ? @procedure.draft_revision : @procedure.active_revision,
      groupe_instructeur: @procedure.defaut_groupe_instructeur_for_new_dossier,
      state: Dossier.states.fetch(:brouillon),
      deleted_user_email_never_send: true
    )
    dossier.build_default_individual
    if dossier.save
      # TODO: SEB dossier.prefill!(PrefillParams.new(dossier, params).to_a)
      render json: { dossier_url: brouillon_dossier_url(dossier) }, status: :created
    else
      render_bad_request(dossier.errors.full_messages.to_sentence)
    end
  end

  private

  def check_procedure_id_presence
    render_missing_param(:procedure_id) if params[:procedure_id].blank?
  end

  def retreive_procedure
    @procedure = Procedure.publiees_ou_brouillons.opendata.find_by(id: params[:procedure_id])
    render_not_found("procedure", params[:procedure_id]) if @procedure.blank?
  end
end
