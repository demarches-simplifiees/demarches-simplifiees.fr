class GraphqlController < ApplicationController
  before_action :authenticate_administrateur!

  def playground
    procedure = current_administrateur.procedures.first
    dossier = procedure.dossiers.first

    gon.default_query = API::V2::StoredQuery.get('ds-query-v2')
    gon.default_variables = {
      "demarcheNumber": procedure.id,
      "dossierNumber": dossier.id,
      "includeDossiers": true
    }.to_json

    render :playground, layout: false
  end
end
