class Champs::CarteController < ApplicationController
  before_action :authenticate_account!

  def show
    @selector = ".carte-#{params[:position]}"

    if params[:dossier].key?(:champs_attributes)
      geo_json = params[:dossier][:champs_attributes][params[:position]][:value]
    else
      geo_json = params[:dossier][:champs_private_attributes][params[:position]][:value]
    end

    if params[:champ_id].present? && current_account.usager?
      @champ = Champ
        .joins(:dossier)
        .where(dossiers: { user_id: current_account.id })
        .find_by(id: params[:champ_id])
    else
      @champ = Champs::CarteChamp.new(type_de_champ: TypeDeChamp.new(
        type_champ: TypeDeChamp.type_champs.fetch(:carte),
        options: {
          quartiers_prioritaires: true,
          cadastres: true
        }
      ))
    end

    geo_areas = []
    geo_json = geo_json.blank? ? [] : JSON.parse(geo_json)

    if geo_json.first == ["error", "TooManyPolygons"]
      @error = true
    elsif geo_json.present?
      if @champ.cadastres?
        cadastres = ModuleApiCartoService.generate_cadastre(geo_json)
        geo_areas += cadastres.map do |cadastre|
          cadastre[:source] = GeoArea.sources.fetch(:cadastre)
          cadastre
        end
      end

      if @champ.quartiers_prioritaires?
        quartiers_prioritaires = ModuleApiCartoService.generate_qp(geo_json)
        geo_areas += quartiers_prioritaires.map do |qp|
          qp[:source] = GeoArea.sources.fetch(:quartier_prioritaire)
          qp
        end
      end

      if @champ.parcelles_agricoles?
        parcelles_agricoles = ModuleApiCartoService.generate_rpg(geo_json)
        geo_areas += parcelles_agricoles.map do |parcelle_agricole|
          parcelle_agricole[:source] = GeoArea.sources.fetch(:parcelle_agricole)
          parcelle_agricole
        end
      end
    end

    @champ.geo_areas = geo_areas.map do |geo_area|
      GeoArea.new(geo_area)
    end

    @champ.value = geo_json.to_json

    if @champ.persisted?
      @champ.save
    end
  end
end
