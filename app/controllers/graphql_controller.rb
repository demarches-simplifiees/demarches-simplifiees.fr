# frozen_string_literal: true

class GraphqlController < ApplicationController
  def playground
    procedure = current_administrateur&.procedures&.last
    gon.default_variables = {
      "demarcheNumber": procedure&.id || 42,
      "includeDossiers": true,
    }.compact.to_json
    gon.default_query = API::V2::StoredQuery.get('ds-query-v2')

    render :playground, layout: false
  end
end
