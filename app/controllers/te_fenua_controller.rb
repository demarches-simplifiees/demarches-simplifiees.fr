class TeFenuaController < ApplicationController
  def suggestions
    request = params[:request]
    json = ApiTeFenua::PlaceAdapter.new(request).suggestions.to_json
    render json: json
  end
end
