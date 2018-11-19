class API::V2::DemarchesController < API::V2::BaseController
  def show
    variables = { id: params[:id] }

    result = Api::V2::Client.query(Queries::Demarche,
      variables: variables,
      context: context)

    render_data(result)
  end

  def instructeurs
    variables = { id: params[:id] }

    result = Api::V2::Client.query(Queries::DemarcheWithInstructeurs,
      variables: variables,
      context: context)

    render_data(result) do |data|
      data.demarche.to_h
    end
  end
end
