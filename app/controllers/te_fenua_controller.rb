class TeFenuaController < ApplicationController
  def suggestions
    request = params[:request]
    json = APITeFenua::PlaceAdapter.new(request).suggestions.to_json
    render json: json
  end
end
