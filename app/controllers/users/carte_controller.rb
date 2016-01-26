class Users::CarteController < UsersController
  include DossierConcern

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

    dossier.quartier_prioritaires.map(&:destroy)
    dossier.cadastres.map(&:destroy)

    unless params[:json_latlngs].blank?
      if dossier.procedure.module_api_carto.quartiers_prioritaires?
        qp_list = generate_qp JSON.parse(params[:json_latlngs])

        qp_list.each do |key, qp|
          qp.merge!({dossier_id: dossier.id})
          qp[:geometry] = qp[:geometry].to_json
          QuartierPrioritaire.create(qp)
        end
      end

      if dossier.procedure.module_api_carto.cadastre?
        cadastre_list = generate_cadastre JSON.parse(params[:json_latlngs])

        cadastre_list.each do |cadastre|
          cadastre.merge!({dossier_id: dossier.id})
          cadastre[:geometry] = cadastre[:geometry].to_json
          Cadastre.create(cadastre)
        end
      end
    end

    dossier.update_attributes(json_latlngs: params[:json_latlngs])

    if dossier.draft?
      redirect_to url_for(controller: :description, action: :show, dossier_id: params[:dossier_id])
    else
      commentaire_params = {
          email: 'Modification localisation',
          body: 'La localisation de la demande a été modifiée. Merci de le prendre en compte.',
          dossier_id: dossier.id
      }
      Commentaire.create commentaire_params
      redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: params[:dossier_id])
    end
  end

  def get_position
    tmp_position = Carto::Geocodeur.convert_adresse_to_point(current_user_dossier.etablissement.geo_adresse)

    if !tmp_position.point.nil?
      render json: {lon: tmp_position.point.x.to_s, lat: tmp_position.point.y.to_s, dossier_id: params[:dossier_id]}
    else
      render json: {lon: '0', lat: '0', dossier_id: params[:dossier_id]}
    end
  end

  def get_qp
    qp = generate_qp JSON.parse(params[:coordinates])

    render json: {quartier_prioritaires: qp}
  end

  def get_cadastre
    cadastres = generate_cadastre JSON.parse(params[:coordinates])

    render json: {cadastres: cadastres}
  end

  def self.route_authorization
    {
        states: [:draft, :initiated, :replied, :updated],
        api_carto: true
    }
  end

  private

  def generate_qp coordinates
    qp = {}

    coordinates.each_with_index do |coordinate, index|
      coordinate = coordinates[index].map { |latlng| [latlng['lng'], latlng['lat']] }
      qp = qp.merge CARTO::SGMAP::QuartiersPrioritaires::Adapter.new(coordinate).to_params
    end

    qp
  end

  def generate_cadastre coordinates
    cadastre = []

    coordinates.each_with_index do |coordinate, index|
      coordinate = coordinates[index].map { |latlng| [latlng['lng'], latlng['lat']] }
      cadastre << CARTO::SGMAP::Cadastre::Adapter.new(coordinate).to_params
    end

    cadastre.flatten
  end
end
