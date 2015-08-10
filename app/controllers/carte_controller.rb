class CarteController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
  rescue
    redirect_to url_for({controller: :start, action: :error_dossier})
  end

  def save_ref_api_carto
    @dossier = Dossier.find(params[:dossier_id])
    @dossier.ref_dossier = params[:ref_dossier]
    @dossier.save

    if params[:back_url] == 'recapitulatif'
      @commentaire = Commentaire.create
      @commentaire.email = 'Modification localisation'
      @commentaire.body = 'La localisation de la demande a été modifiée. Merci de le prendre en compte.'
      @commentaire.dossier = @dossier
      @commentaire.save

      redirect_to url_for({controller: :recapitulatif, action: :show, :dossier_id => params[:dossier_id]})
    else
      redirect_to url_for({controller: :description, action: :show, :dossier_id => params[:dossier_id]})
    end
  end

  def get_position
    @dossier = Dossier.find(params[:dossier_id])

    if @dossier.position_lat == nil
      tmp_position = Carto::Geocodeur.convert_adresse_to_point(@dossier.etablissement.adresse.gsub("\r\n", ' '))

      @dossier.position_lat = tmp_position.point.y
      @dossier.position_lon = tmp_position.point.x

      @dossier.save
    end

    render json: { lon: @dossier.position_lon, lat: @dossier.position_lat, dossier_id: params[:dossier_id] }
  end
end