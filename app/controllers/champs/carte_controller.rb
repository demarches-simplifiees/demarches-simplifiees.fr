class Champs::CarteController < ApplicationController
  before_action :authenticate_logged_user!

  EMPTY_GEO_JSON = '[]'
  ERROR_GEO_JSON = ''

  def show
    @selector = ".carte-#{params[:position]}"

    if params[:dossier].key?(:champs_attributes)
      coordinates = params[:dossier][:champs_attributes][params[:position]][:value]
    else
      coordinates = params[:dossier][:champs_private_attributes][params[:position]][:value]
    end

    @champ = if params[:champ_id].present?
      policy_scope(Champ).find(params[:champ_id])
    else
      policy_scope(TypeDeChamp).find(params[:type_de_champ_id]).champ.build
    end

    geo_areas = []

    if coordinates == EMPTY_GEO_JSON
      @champ.value = nil
      @champ.geo_areas = []
    elsif coordinates == ERROR_GEO_JSON
      @error = true
      @champ.value = nil
      @champ.geo_areas = []
    else
      coordinates = JSON.parse(coordinates)

      if @champ.cadastres?
        cadastres = ApiCartoService.generate_cadastre(coordinates)
        geo_areas += cadastres.map do |cadastre|
          cadastre[:source] = GeoArea.sources.fetch(:cadastre)
          cadastre
        end
      end

      if @champ.quartiers_prioritaires?
        quartiers_prioritaires = ApiCartoService.generate_qp(coordinates)
        geo_areas += quartiers_prioritaires.map do |qp|
          qp[:source] = GeoArea.sources.fetch(:quartier_prioritaire)
          qp
        end
      end

      selection_utilisateur = ApiCartoService.generate_selection_utilisateur(coordinates)
      selection_utilisateur[:source] = GeoArea.sources.fetch(:selection_utilisateur)
      geo_areas << selection_utilisateur

      @champ.geo_areas = geo_areas.map do |geo_area|
        GeoArea.new(geo_area)
      end

      @champ.value = coordinates.to_json
    end

    if @champ.persisted?
      @champ.save
    end

  rescue RestClient::ResourceNotFound
    flash.alert = 'Les données cartographiques sont temporairement indisponibles. Réessayez dans un instant.'
    response.status = 503
  end
end
