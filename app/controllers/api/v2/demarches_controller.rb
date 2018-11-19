class API::V2::DemarchesController < API::V2::BaseController
  def show
    variables = { id: params[:id] }

    result = Api::V2::Client.query(Queries::Demarche,
      variables: variables,
      context: context)

    render_demarche(result)
  end
end
