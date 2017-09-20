module NewGestionnaire
  class AvisController < ApplicationController
    layout 'new_application'

    A_DONNER_STATUS = 'a-donner'
    DONNES_STATUS   = 'donnes'

    def index
      gestionnaire_avis = current_gestionnaire.avis.includes(dossier: [:procedure, :user])
      @avis_a_donner, @avis_donnes = gestionnaire_avis.partition { |avis| avis.answer.nil? }

      @statut = params[:statut].present? ? params[:statut] : A_DONNER_STATUS

      @avis = case @statut
      when A_DONNER_STATUS
        @avis_a_donner
      when DONNES_STATUS
        @avis_donnes
      end
    end

    def show
      @avis = avis
      @dossier = avis.dossier
    end

    def instruction
      @avis = avis
      @dossier = avis.dossier
    end

    def update
      avis.update_attributes(avis_params)
      flash.notice = 'Votre réponse est enregistrée.'
      redirect_to instruction_avis_path(avis)
    end

    def messagerie
      @avis = avis
      @dossier = avis.dossier
    end

    def create_commentaire
      Commentaire.create(commentaire_params.merge(email: current_gestionnaire.email, dossier: avis.dossier))
      redirect_to messagerie_avis_path(avis)
    end

    def create_avis
      confidentiel = avis.confidentiel || params[:avis][:confidentiel]
      Avis.create(create_avis_params.merge(claimant: current_gestionnaire, dossier: avis.dossier, confidentiel: confidentiel))
      redirect_to instruction_avis_path(avis)
    end

    private

    def avis
      current_gestionnaire.avis.includes(dossier: [:avis, :commentaires]).find(params[:id])
    end

    def avis_params
      params.require(:avis).permit(:answer)
    end

    def commentaire_params
      params.require(:commentaire).permit(:body)
    end

    def create_avis_params
      params.require(:avis).permit(:email, :introduction)
    end
  end
end
