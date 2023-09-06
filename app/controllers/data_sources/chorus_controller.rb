class DataSources::ChorusController < ApplicationController
  before_action :authenticate_administrateur!

  def search_domaine_fonct
    @result = APIBretagneService.new.search_domaine_fonct(code_or_label: params[:q])
    result_json = @result.map do |item|
      {
        label: ChorusConfiguration.format_domaine_fonctionnel_label(item),
        value: "#{item[:label]} - #{item[:code_programme]}",
        data: item
      }
    end
    render json: result_json
  end

  def search_centre_couts
    @result = APIBretagneService.new.search_centre_couts(code_or_label: params[:q])
    result_json = @result.map do |item|
      {
        label: ChorusConfiguration.format_domaine_fonctionnel_label(item),
        value: "#{item[:label]} - #{item[:code_programme]}",
        data: item
      }
    end
    render json: result_json
    end

  def search_ref_programmation
    @result = APIBretagneService.new.search_ref_programmation(code_or_label: params[:q])
    result_json = @result.map do |item|
      {
        label: ChorusConfiguration.format_domaine_fonctionnel_label(item),
        value: "#{item[:label]} - #{item[:code_programme]}",
        data: item
      }
    end
    render json: result_json
    end

  # def search
  #   if params[:q].present? && params[:q].length > 3
  #     response = Typhoeus.get("#{API_ADRESSE_URL}/search", params: { q: params[:q], limit: 10 })
  #     result = JSON.parse(response.body, symbolize_names: true)
  #     render json: result[:features].map { { label: _1[:properties][:label], value: _1[:properties][:label] } }
  #   else
  #     render json: []
  #   end
  # end
end
