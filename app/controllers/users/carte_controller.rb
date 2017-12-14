class Users::CarteController < UsersController
  before_action only: [:show] do
    authorized_routes? self.class
  end

  def show
    @dossier = current_user_dossier

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  def save
    dossier = current_user_dossier

    dossier.quartier_prioritaires.each(&:destroy)
    dossier.cadastres.each(&:destroy)

    unless params[:json_latlngs].blank?
      ModuleApiCartoService.save_qp! dossier, params[:json_latlngs]
      ModuleApiCartoService.save_cadastre! dossier, params[:json_latlngs]
    end

    dossier.update_attributes(json_latlngs: params[:json_latlngs])

    controller = :recapitulatif
    controller = :description if dossier.draft?

    redirect_to url_for(controller: controller, action: :show, dossier_id: params[:dossier_id])
  end

  def get_position
    begin
      etablissement = current_user_dossier.etablissement
    rescue ActiveRecord::RecordNotFound
      etablissement = nil
    end

    point = Carto::Geocodeur.convert_adresse_to_point(etablissement.geo_adresse) unless etablissement.nil?

    lon = '2.428462'
    lat = '46.538192'
    zoom = '13'

    unless point.nil?
      lon = point.x.to_s
      lat = point.y.to_s
    end

    render json: {lon: lon, lat: lat, zoom: zoom, dossier_id: params[:dossier_id]}
  end

  def get_qp
    render json: {quartier_prioritaires: ModuleApiCartoService.generate_qp(JSON.parse(params[:coordinates]))}
  end

  def get_cadastre
    render json: {cadastres: ModuleApiCartoService.generate_cadastre(JSON.parse(params[:coordinates]))}
  end

  def self.route_authorization
    {
        states: [:draft, :en_construction],
        api_carto: true
    }
  end
end
