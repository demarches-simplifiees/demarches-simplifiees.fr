class Users::CarteController < UsersController
  include DossierConcern

  def show
    @dossier = current_user_dossier
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  def save
    dossier = current_user_dossier

    dossier.quartier_prioritaires.map(&:destroy)

    unless params[:json_latlngs].blank?
      qp_list = generate_qp JSON.parse(params[:json_latlngs])

      qp_list.each do |key, qp|
        qp.merge!({dossier_id: dossier.id})
        qp[:geometry] = qp[:geometry].to_json
        QuartierPrioritaire.new(qp).save
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
    tmp_position = Carto::Geocodeur.convert_adresse_to_point(current_user_dossier.etablissement.adresse.gsub("\r\n", ' '))

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

  private

  def generate_qp coordinates
    qp = {}

    coordinates.each_with_index do |coordinate, index|
      coordinate = coordinates[index].map { |latlng| [latlng['lng'], latlng['lat']] }
      qp = qp.merge CARTO::SGMAP::QuartierPrioritaireAdapter.new(coordinate).to_params
    end

    qp
  end
end
