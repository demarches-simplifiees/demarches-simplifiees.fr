class API::Public::V1::DossiersController < API::Public::V1::BaseController
  before_action :retrieve_procedure

  def create
    dossier = Dossier.new(
      revision: @procedure.active_revision,
      groupe_instructeur: @procedure.defaut_groupe_instructeur_for_new_dossier,
      state: Dossier.states.fetch(:brouillon),
      prefilled: true
    )
    dossier.build_default_individual
    if dossier.save
      dossier.prefill!(PrefillParams.new(dossier, params.to_unsafe_h).to_a)
      render json: { dossier_url: commencer_url(@procedure.path, prefill_token: dossier.prefill_token) }, status: :created
    else
      render_bad_request(dossier.errors.full_messages.to_sentence)
    end
  end

  private

  def retrieve_procedure
    @procedure = Procedure.publiees_ou_brouillons.find_by(id: params[:id])
    render_not_found("procedure", params[:id]) if @procedure.blank?
  end
end
