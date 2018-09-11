module NewGestionnaire
  class AvisController < GestionnaireController
    before_action :authenticate_gestionnaire!, except: [:sign_up, :create_gestionnaire]
    before_action :redirect_if_no_sign_up_needed, only: [:sign_up]
    before_action :check_avis_exists_and_email_belongs_to_avis, only: [:sign_up, :create_gestionnaire]
    before_action :set_avis_and_dossier, only: [:show, :instruction, :messagerie, :create_commentaire, :update]

    A_DONNER_STATUS = 'a-donner'
    DONNES_STATUS   = 'donnes'

    def index
      gestionnaire_avis = current_gestionnaire.avis.includes(dossier: [:procedure, :user])
      @avis_a_donner = gestionnaire_avis.without_answer
      @avis_donnes = gestionnaire_avis.with_answer

      @statut = params[:statut].presence || A_DONNER_STATUS

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
      @new_avis = Avis.new
    end

    def update
      if @avis.update(avis_params)
        flash.notice = 'Votre réponse est enregistrée.'
        redirect_to instruction_gestionnaire_avis_path(@avis)
      else
        flash.now.alert = @avis.errors.full_messages
        @new_avis = Avis.new
        render :instruction
      end
    end

    def messagerie
      @commentaire = Commentaire.new
    end

    def create_commentaire
      @commentaire = Commentaire.new(commentaire_params.merge(email: current_gestionnaire.email, dossier: avis.dossier))

      if @commentaire.save
        flash.notice = "Message envoyé"
        redirect_to messagerie_gestionnaire_avis_path(avis)
      else
        flash.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def create_avis
      confidentiel = avis.confidentiel || create_avis_params[:confidentiel]
      @new_avis = Avis.new(create_avis_params.merge(claimant: current_gestionnaire, dossier: avis.dossier, confidentiel: confidentiel))

      if @new_avis.save
        flash.notice = "Une demande d'avis a été envoyée à #{@new_avis.email_to_display}"
        redirect_to instruction_gestionnaire_avis_path(avis)
      else
        flash.now.alert = @new_avis.errors.full_messages
        set_avis_and_dossier
        render :instruction
      end
    end

    def sign_up
      @email = params[:email]
      @dossier = Avis.includes(:dossier).find(params[:id]).dossier

      render layout: 'new_application'
    end

    def create_gestionnaire
      email = params[:email]
      password = params['gestionnaire']['password']

      gestionnaire = Gestionnaire.new(email: email, password: password)

      if gestionnaire.save
        user = User.find_by(email: email)
        if user.blank?
          user = User.create(email: email, password: password, confirmed_at: Time.zone.now)
        end

        sign_in(user)
        sign_in(gestionnaire, scope: :gestionnaire)

        Avis.link_avis_to_gestionnaire(gestionnaire)
        redirect_to url_for(gestionnaire_avis_index_path)
      else
        flash[:alert] = gestionnaire.errors.full_messages
        redirect_to url_for(sign_up_gestionnaire_avis_path(params[:id], email))
      end
    end

    private

    def set_avis_and_dossier
      @avis = avis
      @dossier = avis.dossier
    end

    def redirect_if_no_sign_up_needed
      avis = Avis.find(params[:id])

      if current_gestionnaire.present?
        # a gestionnaire is authenticated ... lets see if it can view the dossier

        redirect_to gestionnaire_avis_url(avis)
      elsif avis.gestionnaire&.email == params[:email]
        # the avis gestionnaire has already signed up and it sould sign in

        redirect_to new_gestionnaire_session_url
      end
    end

    def check_avis_exists_and_email_belongs_to_avis
      if !Avis.avis_exists_and_email_belongs_to_avis?(params[:id], params[:email])
        redirect_to url_for(root_path)
      end
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
      params.require(:avis).permit(:email, :introduction, :confidentiel)
    end
  end
end
