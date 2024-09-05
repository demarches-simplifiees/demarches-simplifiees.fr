# frozen_string_literal: true

class DataSources::CommuneController < ApplicationController
  def search
    if params[:q].present? && params[:q].length > 1
      response = APIGeoService.commune_by_name_or_postal_code(params[:q])

      if response.success?
        results = JSON.parse(response.body, symbolize_names: true)

        render json: APIGeoService.format_commune_response(results, params[:with_combined_code])
      else
        render json: []
      end
    else
      render json: []
    end
  end
end
