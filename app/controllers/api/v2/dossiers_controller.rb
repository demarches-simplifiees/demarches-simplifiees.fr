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

  def state
    variables = {
      dossier_id: params.require(:id),
      instructeur_id: params[:instructeur_id],
      motivation: params[:motivation]
    }

    result = case params.require(:state).downcase
    when Dossier.states.fetch(:en_instruction)
      Api::V2::Client.query(Queries::DossierPasserEnInstruction,
        variables: variables,
        context: context)
    when Dossier.states.fetch(:en_construction)
      Api::V2::Client.query(Queries::DossierRepasserEnConstruction,
        variables: variables,
        context: context)
    when Dossier.states.fetch(:accepte)
      Api::V2::Client.query(Queries::DossierAccepter,
        variables: variables,
        context: context)
    when Dossier.states.fetch(:sans_suite)
      Api::V2::Client.query(Queries::DossierClasserSansSuite,
        variables: variables,
        context: context)
    when Dossier.states.fetch(:refuse)
      Api::V2::Client.query(Queries::DossierRefuser,
        variables: variables,
        context: context)
    end

    render_data(result) do |data|
      { data: data.payload.dossier.to_h }
    end
  end
end
