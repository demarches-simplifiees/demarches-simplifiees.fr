class Champs::CarteController < ApplicationController
  before_action :authenticate_logged_user!

  def index
    @champ = policy_scope(Champ).find(params[:champ_id])
    @focus = params[:focus].present?
  end

  def create
    champ = policy_scope(Champ).find(params[:champ_id])
    geo_area = if params_source == GeoArea.sources.fetch(:cadastre)
      champ.geo_areas.find_by("properties->>'id' = :id", id: create_params_feature[:properties][:id])
    end

    if geo_area.nil?
      geo_area = champ.geo_areas.build(source: params_source, properties: {})

      if save_feature(geo_area, create_params_feature)
        render json: { feature: geo_area.to_feature }, status: :created
      else
        render json: { errors: geo_area.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { feature: geo_area.to_feature }, status: :ok
    end
  end

  def update
    champ = policy_scope(Champ).find(params[:champ_id])
    geo_area = champ.geo_areas.find(params[:id])

    if save_feature(geo_area, update_params_feature)
      head :no_content
    else
      render json: { errors: geo_area.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    champ = policy_scope(Champ).find(params[:champ_id])
    champ.geo_areas.find(params[:id]).destroy!
    champ.touch

    head :no_content
  end

  private

  def params_source
    params[:source]
  end

  def create_params_feature
    params.require(:feature).permit(properties: [
      :filename,
      :description,
      :arpente,
      :commune,
      :contenance,
      :created,
      :id,
      :numero,
      :prefixe,
      :section,
      :updated
    ]).tap do |feature|
      feature[:geometry] = params[:feature][:geometry]
    end
  end

  def update_params_feature
    params.require(:feature).permit(properties: [:description]).tap do |feature|
      feature[:geometry] = params[:feature][:geometry]
    end
  end

  def save_feature(geo_area, feature)
    if feature[:geometry]
      geo_area.geometry = feature[:geometry]
    end
    if feature[:properties]
      geo_area.properties.merge!(feature[:properties])
    end
    if geo_area.save
      geo_area.champ.touch
      true
    end
  end
end
