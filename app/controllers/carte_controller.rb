class CarteController < ApplicationController
  include DossierConcern
  centre_de_la_France = 'Vesdun'

  def show
    @dossier = current_dossier
  rescue
    redirect_to url_for({controller: :start, action: :error_dossier})
  end

  def save_ref_api_carto
    dossier = current_dossier
    dossier.update_attributes(ref_dossier: params[:ref_dossier])

    if params[:back_url] == 'recapitulatif'
      commentaire = Commentaire.new
      commentaire.email = 'Modification localisation'
      commentaire.body = 'La localisation de la demande a été modifiée. Merci de le prendre en compte.'
      commentaire.dossier = dossier
      commentaire.save

      redirect_to url_for({controller: :recapitulatif, action: :show, :dossier_id => params[:dossier_id]})
    else
      redirect_to url_for({controller: :description, action: :show, :dossier_id => params[:dossier_id]})
    end
  end

  def get_position
    dossier = current_dossier

    if dossier.position_lat == nil
      tmp_position = Carto::Geocodeur.convert_adresse_to_point(dossier.etablissement.adresse.gsub("\r\n", ' '))

      if tmp_position.point == nil
        dossier.update_attributes(position_lat: '0', position_lon: '0')
      else
        dossier.update_attributes(position_lat: tmp_position.point.y, position_lon: tmp_position.point.x)
      end
    end

    render json: { lon: dossier.position_lon, lat: dossier.position_lat, dossier_id: params[:dossier_id] }
  end
end