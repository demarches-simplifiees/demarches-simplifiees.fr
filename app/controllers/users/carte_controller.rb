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
    safe_json_latlngs = clean_json_latlngs(params[:json_latlngs])
    dossier = current_user_dossier

    dossier.quartier_prioritaires.each(&:destroy)
    dossier.cadastres.each(&:destroy)

    if safe_json_latlngs.present?
      ModuleApiCartoService.save_qp! dossier, safe_json_latlngs
      ModuleApiCartoService.save_cadastre! dossier, safe_json_latlngs
    end

    dossier.update(json_latlngs: safe_json_latlngs)

    redirect_to brouillon_dossier_path(dossier)
  end

  def zones
    @dossier = current_user_dossier
    @data = {}

    geo_json = JSON.parse(params.required(:selection))

    if geo_json.first == ["error", "TooManyPolygons"]
      @error = true
    else
      if @dossier.procedure.module_api_carto.quartiers_prioritaires?
        quartiers_prioritaires = ModuleApiCartoService.generate_qp(geo_json).values
        @dossier.quartier_prioritaires.build(quartiers_prioritaires)
        @data[:quartiersPrioritaires] = quartiers_prioritaires
      end

      if @dossier.procedure.module_api_carto.cadastre?
        cadastres = ModuleApiCartoService.generate_cadastre(geo_json)
        @dossier.cadastres.build(cadastres)
        @data[:cadastres] = cadastres
      end
    end
  end

  def self.route_authorization
    {
      states: [Dossier.states.fetch(:brouillon), Dossier.states.fetch(:en_construction)],
      api_carto: true
    }
  end

  private

  def clean_json_latlngs(json_latlngs)
    # a polygon must contain at least 4 points
    # https://tools.ietf.org/html/rfc7946#section-3.1.6
    if json_latlngs.present?
      multipolygone = JSON.parse(json_latlngs)
      multipolygone.reject! { |polygone| polygone.count < 4 }
      if multipolygone.present?
        multipolygone.to_json
      end
    end
  end
end
