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
end
