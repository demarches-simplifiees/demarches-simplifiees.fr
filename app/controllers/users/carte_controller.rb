class Users::CarteController < UsersController
  include DossierConcern

  def show
    @dossier = current_user_dossier
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  #TODO change name funtion
  def save_ref_api_carto
    dossier = current_user_dossier
    dossier.update_attributes(json_latlngs: params[:json_latlngs])

    if dossier.draft?
      redirect_to url_for(controller: :description, action: :show, dossier_id: params[:dossier_id])
    else
      commentaire_params = {
          email: 'Modification localisation',
          body: 'La localisation de la demande a été modifiée. Merci de le prendre en compte.',
          dossier_id: dossier.id
      }
      commentaire = Commentaire.new commentaire_params
      commentaire.save
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
end
