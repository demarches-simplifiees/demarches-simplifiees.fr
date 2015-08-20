class DossiersController < ApplicationController
  def show
    @dossier = Dossier.find(params[:id])

    @etablissement =  @dossier.etablissement
    @entreprise =  @dossier.entreprise.decorate
  rescue ActiveRecord::RecordNotFound
    redirect_to url_for(controller: :start, action: :error_dossier)
  end

  def create
    @dossier_id = params[:pro_dossier_id].strip

    if dossier_id_is_present?

      @dossier = Dossier.find(@dossier_id)

      if @dossier.siret == params[:siret]
        redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: @dossier_id)
      else
        redirect_to url_for(controller: :start, action: :error_dossier)
      end
    else

      @etablissement = Etablissement.new(SIADE::EtablissementAdapter.new(siret).to_params)
      @entreprise = Entreprise.new(SIADE::EntrepriseAdapter.new(siren).to_params)
      @dossier = Dossier.create

      @entreprise.dossier = @dossier
      @entreprise.save

      @etablissement.dossier = @dossier
      @etablissement.entreprise = @entreprise
      @etablissement.save

      redirect_to url_for(controller: :dossiers, action: :show, id: @dossier.id)
    end

  rescue RestClient::ResourceNotFound
    redirect_to url_for(controller: :start, action: :error_siret)
  rescue ActiveRecord::RecordNotFound
    redirect_to url_for(controller: :start, action: :error_dossier)
  end

  def update
    @dossier = Dossier.find(params[:id])
    if checked_autorisation_donnees?
      @dossier.update_attributes(update_params)
      redirect_to url_for(controller: :demandes, action: :show, dossier_id: @dossier.id)
    else
      @etablissement =  @dossier.etablissement
      @entreprise =  @dossier.entreprise.decorate
      flash.now.alert = 'Les conditions sont obligatoires.'
      render 'show'
    end
  end

  private

  def update_params
    params.require(:dossier).permit(:autorisation_donnees)
  end

  def dossier_id_is_present?
    @dossier_id != ''
  end

  def checked_autorisation_donnees?
    update_params[:autorisation_donnees] == '1'
  end

  def siret
    params[:siret]
  end

  def siren
    siret[0..8]
  end
end
