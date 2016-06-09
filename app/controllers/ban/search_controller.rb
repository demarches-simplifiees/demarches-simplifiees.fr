class Ban::SearchController < ApplicationController
  def get
    request = params[:request]

    render json: Carto::Bano::AddressRetriever.new(request).list.inject([]) {
               |acc, value| acc.push({label: value})
           }.to_json
  end
end