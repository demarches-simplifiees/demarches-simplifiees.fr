class API::V2::DossiersController < API::V2::BaseController
  def show
    variables = { id: params[:id] }

    result = Api::V2::Client.query(Queries::Dossier,
      variables: variables,
      context: context)

    render_data(result)
  end

  def index
    variables = {
      id: params[:demarche_id],
      after: params[:after],
      first: params.fetch(:limit, 100).to_i,
      ids: params[:ids],
      since: params[:since]
    }

    result = Api::V2::Client.query(Queries::DemarcheWithDossiers,
      variables: variables,
      context: context)

    render_data(result) do |data|
      data.demarche.dossiers.to_h
    end
  end
end
