# frozen_string_literal: true

class DataSources::ChorusController < ApplicationController
  before_action :authenticate_administrateur!

  def search_domaine_fonct
    result_json = APIBretagneService.new.search_domaine_fonct(code_or_label: params[:q])
    render json: format_result(result_json:,
                               label_formatter: ChorusConfiguration.method(:format_domaine_fonctionnel_label))
  end

  def search_centre_couts
    result_json = APIBretagneService.new.search_centre_couts(code_or_label: params[:q])
    render json: format_result(result_json:,
                               label_formatter: ChorusConfiguration.method(:format_centre_de_cout_label))
    end

  def search_ref_programmation
    result_json = APIBretagneService.new.search_ref_programmation(code_or_label: params[:q])
    render json: format_result(result_json:,
                               label_formatter: ChorusConfiguration.method(:format_ref_programmation_label))
  end

  private

  def format_result(result_json:, label_formatter:)
    result_json.map do |item|
      {
        label: label_formatter.call(item),
        value: item[:code],
        data: item
      }
    end
  end
end
