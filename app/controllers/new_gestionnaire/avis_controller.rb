module NewGestionnaire
  class AvisController < ApplicationController
    layout 'new_application'

    before_action :set_avis_and_dossier, only: [:show, :instruction, :messagerie, :create_commentaire]

    A_DONNER_STATUS = 'a-donner'
    DONNES_STATUS   = 'donnes'

    def index
      gestionnaire_avis = current_gestionnaire.avis.includes(dossier: [:procedure, :user])
      @avis_a_donner = gestionnaire_avis.without_answer
      @avis_donnes = gestionnaire_avis.with_answer

      @statut = params[:statut].present? ? params[:statut] : A_DONNER_STATUS

      @avis = case @statut
      when A_DONNER_STATUS
        @avis_a_donner
      when DONNES_STATUS
        @avis_donnes
      end

      @avis = @avis.page([params[:page].to_i, 1].max)
    end

    def show
    end

    def instruction
    end

    def update
      avis.update_attributes(avis_params)
      flash.notice = 'Votre réponse est enregistrée.'
      redirect_to instruction_avis_path(avis)
    end

    def messagerie
      @commentaire = Commentaire.new
    end

    def create_commentaire
      @commentaire = Commentaire.new(commentaire_params.merge(email: current_gestionnaire.email, dossier: avis.dossier))

      if @commentaire.save
        flash.notice = "Message envoyé"
        redirect_to messagerie_avis_path(avis)
      else
        flash.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def create_avis
      confidentiel = avis.confidentiel || params[:avis][:confidentiel]
      Avis.create(create_avis_params.merge(claimant: current_gestionnaire, dossier: avis.dossier, confidentiel: confidentiel))
      redirect_to instruction_avis_path(avis)
    end

    private

    def set_avis_and_dossier
      @avis = avis
      @dossier = avis.dossier
    end

    def avis
      current_gestionnaire.avis.includes(dossier: [:avis, :commentaires]).find(params[:id])
    end

    def avis_params
      params.require(:avis).permit(:answer)
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, :file)
    end

    def create_avis_params
      params.require(:avis).permit(:email, :introduction)
    end
  end
end
