class Champs::CarteController < ApplicationController
  before_action :authenticate_logged_user!

  ERROR_GEO_JSON = ''

  def show
    @selector = ".carte-#{params[:position]}"

    feature_collection = if params[:dossier].key?(:champs_attributes)
      params[:dossier][:champs_attributes][params[:position]][:value]
    else
      params[:dossier][:champs_private_attributes][params[:position]][:value]
    end

    @champ = if params[:champ_id].present?
      policy_scope(Champ).find(params[:champ_id])
    else
      policy_scope(TypeDeChamp).find(params[:type_de_champ_id]).champ.build
    end

    geo_areas = []

    if feature_collection == ERROR_GEO_JSON
      @error = true
    else
      feature_collection = JSON.parse(feature_collection, symbolize_names: true)

      if @champ.cadastres?
        populate_cadastres(feature_collection)
      end

      geo_areas = GeoArea.from_feature_collection(feature_collection)
    end

    if @champ.persisted?
      @champ.update(value: nil, geo_areas: geo_areas)
    end
  rescue ApiCarto::API::ResourceNotFound
    flash.alert = 'Les données cartographiques sont temporairement indisponibles. Réessayez dans un instant.'
    response.status = 503
  end

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
    save_geometry!(geo_area)

    render json: { feature: geo_area.to_feature }, status: :created
  end

  def update
    champ = policy_scope(Champ).find(params[:champ_id])
    geo_area = champ.geo_areas.selections_utilisateur.find(params[:id])
    save_geometry!(geo_area)

    head :no_content
  end

  def destroy
    champ = policy_scope(Champ).find(params[:champ_id])
    champ.geo_areas.selections_utilisateur.find(params[:id]).destroy!

    head :no_content
  end

  private

  def populate_cadastres(feature_collection)
    coordinates = feature_collection[:features].filter do |feature|
      feature[:geometry][:type] == 'Polygon'
    end.map do |feature|
      feature[:geometry][:coordinates][0].map { |(lng, lat)| { 'lng' => lng, 'lat' => lat } }
    end

    if coordinates.present?
      cadastres = ApiCartoService.generate_cadastre(coordinates)

      feature_collection[:features] += cadastres.map do |cadastre|
        {
          type: 'Feature',
          geometry: cadastre.delete(:geometry),
          properties: cadastre.merge(source: GeoArea.sources.fetch(:cadastre))
        }
      end
    end
  end

  def save_geometry!(geo_area)
    geo_area.geometry = params[:feature][:geometry]
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
