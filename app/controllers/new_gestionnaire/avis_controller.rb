module NewGestionnaire
  class AvisController < ApplicationController
    layout 'new_application'

    def index
      gestionnaire_avis = current_gestionnaire.avis.includes(dossier: [:procedure, :user])
      @avis_a_donner, @avis_donnes = gestionnaire_avis.partition { |avis| avis.answer.nil? }

      @statut = params[:statut].present? ? params[:statut] : 'a-donner'

      @avis = case @statut
      when 'a-donner'
        @avis_a_donner
      when 'donnes'
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
  end
end
