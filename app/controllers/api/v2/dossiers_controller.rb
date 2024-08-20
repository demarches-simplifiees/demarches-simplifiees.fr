class API::V2::DossiersController < API::V2::BaseController
  before_action :ensure_dossier_present
  skip_before_action :authenticate_from_token
  skip_before_action :allow_only_persisted_queries

  def pdf
    @acls = PiecesJustificativesService.new(user_profile: Administrateur.new, export_template: nil).acl_for_dossier_export(dossier.procedure)
    render(template: 'dossiers/show', formats: [:pdf])
  end

  def geojson
    send_data dossier.to_feature_collection.to_json,
      type: 'application/json',
      filename: "dossier-#{dossier.id}-features.json"
  end

  private

  def request_logs(logs)
    super
    if dossier.present?
      logs.merge!(ds_dossier_id: dossier.id.to_s, ds_procedure_id: dossier.procedure.id.to_s)
    end
  end

  def ensure_dossier_present
    if dossier.blank?
      head :unauthorized
    end
  end

  def dossier
    @dossier ||= GlobalID::Locator.locate_signed(params[:id].to_s, for: 'api_v2')
  end
end
