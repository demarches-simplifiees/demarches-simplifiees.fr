class DossiersController < ApplicationController
  def show
    @dossier = Dossier.find(params[:id])

    @etablissement =  @dossier.etablissement
    @entreprise =  @dossier.entreprise.decorate
  rescue
    redirect_to url_for({controller: :start, action: :error_dossier})
  end

  def create
    @rescue_redirect = 'error_siret'

    @etablissement = Etablissement.new(SIADE::EtablissementAdapter.new(params[:siret]).to_params)
    @entreprise = Entreprise.new(SIADE::EntrepriseAdapter.new(params[:siret][0..-6]).to_params)

    @dossier_id = params[:pro_dossier_id].strip

    if @dossier_id != ""
      @rescue_redirect = 'error_dossier'

      @dossier = Dossier.find(@dossier_id)
      @etablissement = @dossier.etablissement

      if @etablissement.siret == params[:siret]
        redirect_to url_for({controller: :recapitulatif, action: :show, dossier_id: @dossier_id})
      else
        raise 'Combinaison Dossier_ID / SIRET non valide'
      end
    else
      @dossier = Dossier.create

      @entreprise.dossier = @dossier
      @entreprise.save

      @etablissement.dossier = @dossier
      @etablissement.entreprise = @entreprise
      @etablissement.save

      redirect_to url_for({controller: :dossiers, action: :show, id: @dossier.id})
    end
  rescue
    redirect_to url_for({controller: :start, action: @rescue_redirect})
  end

  def update
    @dossier = Dossier.find(params[:id])
    @dossier.autorisation_donnees = (params[:autorisation_donnees] == 'on')
    @dossier.save

    if @dossier.autorisation_donnees
      redirect_to url_for({controller: :demandes, action: :show, dossier_id: @dossier.id})
    else
      @etablissement =  @dossier.etablissement
      @entreprise =  @dossier.entreprise.decorate

      self.error
    end
  end

  def error
    show
    flash.now.alert = 'Les conditions sont obligatoires.'
    render 'show'
  end

  private

  def dossier_id_is_present?

  end

  def siret
    params[:siret]
  end

  def siren
    siret[0..8]
  end
end
