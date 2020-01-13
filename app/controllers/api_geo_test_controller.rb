class APIGeoTestController < ActionController::Base
  def regions
    render json: [{ nom: 'Martinique' }]
  end

  def departements
    render json: [{ nom: 'Aisne', code: '02' }]
  end

  def communes
    render json: [{ nom: 'Ambléon' }]
  end
end
