class API::V2::DossiersController < API::V2::BaseController
  def show
    variables = { id: params[:id] }

    result = Api::V2::Client.query(Queries::Dossier,
      variables: variables,
      context: context)

    render_dossier(result)
  end

  def index
    variables = {
      id: params[:demarche_id],
      since: params[:since],
      after: params[:after],
      before: params[:before]
    }

    result = Api::V2::Client.query(Queries::DossiersForDemarche,
      variables: variables,
      context: context)

    render_data(result) do |data|
      data.demarche.dossiers.to_h
    end
  end
end
