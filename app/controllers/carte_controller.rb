class CarteController < ApplicationController
  include DossierConcern

  def show
    @dossier = current_dossier
  rescue ActiveRecord::RecordNotFound
    redirect_to url_for(controller: :start, action: :error_dossier)
  end

  def save_ref_api_carto
    dossier = current_dossier
    if dossier.ref_dossier.blank?
      dossier.update_attributes(ref_dossier: params[:ref_dossier])
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
    dossier = current_dossier

    if dossier.position_lat.nil?
      tmp_position = Carto::Geocodeur.convert_adresse_to_point(dossier.etablissement.adresse.gsub("\r\n", ' '))

      if tmp_position.point.nil?
        dossier.update_attributes(position_lat: '0', position_lon: '0')
      else
        dossier.update_attributes(position_lat: tmp_position.point.y, position_lon: tmp_position.point.x)
      end
    end

    render json: { lon: dossier.position_lon, lat: dossier.position_lat, dossier_id: params[:dossier_id] }
  end
end
