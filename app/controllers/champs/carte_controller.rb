class Champs::CarteController < ApplicationController
  before_action :authenticate_logged_user!

  def index
    @selector = ".carte-#{params[:champ_id]}"
    @champ = policy_scope(Champ).find(params[:champ_id])
    @update_cadastres = params[:cadastres]

    if @champ.cadastres? && @update_cadastres
      @champ.geo_areas.cadastres.destroy_all
      @champ.geo_areas += GeoArea.from_feature_collection(cadastres_features_collection(@champ.to_feature_collection))
      @champ.save!
    end
  rescue ApiCarto::API::ResourceNotFound
    flash.alert = 'Les données cartographiques sont temporairement indisponibles. Réessayez dans un instant.'
    response.status = 503
  end

  def create
    champ = policy_scope(Champ).find(params[:champ_id])
    geo_area = champ.geo_areas.selections_utilisateur.new
    save_geometry!(geo_area, params_feature)

    render json: { feature: geo_area.to_feature }, status: :created
  end

  def update
    champ = policy_scope(Champ).find(params[:champ_id])
    geo_area = champ.geo_areas.selections_utilisateur.find(params[:id])
    save_geometry!(geo_area, params_feature)

    head :no_content
  end

  def destroy
    champ = policy_scope(Champ).find(params[:champ_id])
    champ.geo_areas.selections_utilisateur.find(params[:id]).destroy!

    head :no_content
  end

  def import
    champ = policy_scope(Champ).find(params[:champ_id])
    params_features.each do |feature|
      geo_area = champ.geo_areas.selections_utilisateur.new
      save_geometry!(geo_area, feature)
    end

    render json: champ.to_feature_collection, status: :created
  end

  private

  def params_feature
    params[:feature]
  end

  def params_features
    params[:features]
  end

  def save_geometry!(geo_area, feature)
    geo_area.geometry = feature[:geometry]
    geo_area.save!
  end

  def cadastres_features_collection(feature_collection)
    coordinates = feature_collection[:features].filter do |feature|
      feature[:properties][:source] == GeoArea.sources.fetch(:selection_utilisateur) && feature[:geometry]['type'] == 'Polygon'
    end.map do |feature|
      feature[:geometry]['coordinates'][0].map { |(lng, lat)| { 'lng' => lng, 'lat' => lat } }
    end

    if coordinates.present?
      cadastres = ApiCartoService.generate_cadastre(coordinates)

      {
        type: 'FeatureCollection',
        features: cadastres.map do |cadastre|
          {
            type: 'Feature',
            geometry: cadastre.delete(:geometry),
            properties: cadastre.merge(source: GeoArea.sources.fetch(:cadastre))
          }
        end
      }
    else
      {
        type: 'FeatureCollection',
        features: []
      }
    end
  end
end
