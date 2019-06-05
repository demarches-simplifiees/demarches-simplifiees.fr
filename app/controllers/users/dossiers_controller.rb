module Users
  class DossiersController < UserController
    include Devise::StoreLocationExtension
    include DossierHelper

    layout 'procedure_context', only: [:identite, :update_identite, :siret, :update_siret]

    ACTIONS_ALLOWED_TO_ANY_USER = [:index, :recherche, :new]
    ACTIONS_ALLOWED_TO_OWNER_OR_INVITE = [:show, :demande, :messagerie, :brouillon, :update_brouillon, :modifier, :update, :create_commentaire, :purge_champ_piece_justificative]

    before_action :ensure_ownership!, except: ACTIONS_ALLOWED_TO_ANY_USER + ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_ownership_or_invitation!, only: ACTIONS_ALLOWED_TO_OWNER_OR_INVITE
    before_action :ensure_dossier_can_be_updated, only: [:update_identite, :update_brouillon, :modifier, :update, :purge_champ_piece_justificative]
    before_action :forbid_invite_submission!, only: [:update_brouillon]
    before_action :forbid_closed_submission!, only: [:update_brouillon]
    before_action :show_demarche_en_test_banner
    before_action :store_user_location!, only: :new

    def index
      @user_dossiers = current_user.dossiers.includes(:procedure).order_by_updated_at.page(page)
      @dossiers_invites = current_user.dossiers_invites.includes(:procedure).order_by_updated_at.page(page)

      @current_tab = current_tab(@user_dossiers.count, @dossiers_invites.count)

      @dossiers = case @current_tab
      when 'mes-dossiers'
        @user_dossiers
      when 'dossiers-invites'
        @dossiers_invites
      end
    end

    def show
      if dossier.brouillon?
        redirect_to brouillon_dossier_path(dossier)
      end

      @dossier = dossier
    end

    def demande
      @dossier = dossier
    end

    def messagerie
      @dossier = dossier
      @commentaire = Commentaire.new
    end

    def attestation
      send_data(dossier.attestation.pdf.read, filename: 'attestation.pdf', type: 'application/pdf')
    end

    def identite
      @dossier = dossier
      @user = current_user
    end

    def update_identite
      @dossier = dossier

      if @dossier.individual.update(individual_params)
        @dossier.update!(autorisation_donnees: true)
        flash.notice = "Identité enregistrée"

        redirect_to brouillon_dossier_path(@dossier)
      else
        flash.now.alert = @dossier.individual.errors.full_messages
        render :identite
      end
    end

    def siret
      @dossier = dossier
    end

    def update_siret
      @dossier = dossier

      # We use the user as the holder model object for the siret value
      # (so that we can restore it on the form in case of error).
      #
      # This is the only remaining use of User#siret: it could be refactored away.
      # However some existing users have a siret but no associated etablissement,
      # so we would need to analyze the legacy data and decide what to do with it.
      current_user.siret = siret_params[:siret]

      siret_model = Siret.new(siret: siret_params[:siret])
      if !siret_model.valid?
        return render_siret_error(siret_model.errors.full_messages)
      end

      sanitized_siret = siret_model.siret
      begin
        etablissement_attributes = ApiEntrepriseService.get_etablissement_params_for_siret(sanitized_siret, @dossier.procedure.id)
      rescue RestClient::RequestFailed
        return render_siret_error(t('errors.messages.siret_network_error'))
      end
      if etablissement_attributes.blank?
        return render_siret_error(t('errors.messages.siret_unknown'))
      end

      etablissement = @dossier.build_etablissement(etablissement_attributes)
      etablissement.save!
      current_user.update!(siret: sanitized_siret)
      @dossier.update!(autorisation_donnees: true)

      redirect_to etablissement_dossier_path
    end

    def etablissement
      @dossier = dossier

      # Redirect if the user attempts to access the page URL directly
      if !@dossier.etablissement
        flash.alert = 'Aucun établissement n’est associé à ce dossier'
        return redirect_to siret_dossier_path(@dossier)
      end
    end

    def brouillon
      @dossier = dossier_with_champs

      # TODO: remove when the champs are unifed
      if !@dossier.autorisation_donnees
        if dossier.procedure.for_individual
          redirect_to identite_dossier_path(@dossier)
        else
          redirect_to siret_dossier_path(@dossier)
        end
      end
    end

    # FIXME:
    # - remove PiecesJustificativesService
    # - delegate draft save logic to champ ?
    def update_brouillon
      @dossier = dossier_with_champs

      errors = update_dossier_and_compute_errors

      if errors.present?
        flash.now.alert = errors
        render :brouillon
      else
        if save_draft?
          flash.now.notice = 'Votre brouillon a bien été sauvegardé.'
          render :brouillon
        else
          @dossier.en_construction!
          NotificationMailer.send_initiated_notification(@dossier).deliver_later
          redirect_to merci_dossier_path(@dossier)
        end
      end
    end

    def modifier
      @dossier = dossier_with_champs
    end

    # FIXME:
    # - remove PiecesJustificativesService
    def update
      @dossier = dossier_with_champs

      errors = update_dossier_and_compute_errors

      if errors.present?
        flash.now.alert = errors
        render :modifier
      else
        redirect_to demande_dossier_path(@dossier)
      end
    end

    def merci
      @dossier = current_user.dossiers.includes(:procedure).find(params[:id])
    end

    def create_commentaire
      @commentaire = CommentaireService.build(current_user, dossier, commentaire_params)

      if @commentaire.save
        flash.notice = "Votre message a bien été envoyé à l’instructeur en charge de votre dossier."
        redirect_to messagerie_dossier_path(dossier)
      else
        flash.now.alert = @commentaire.errors.full_messages
        render :messagerie
      end
    end

    def ask_deletion
      dossier = current_user.dossiers.includes(:user, procedure: :administrateurs).find(params[:id])

      if dossier.can_be_deleted_by_user?
        dossier.delete_and_keep_track
        flash.notice = 'Votre dossier a bien été supprimé.'
        redirect_to dossiers_path
      else
        flash.notice = "L'instruction de votre dossier a commencé, il n'est plus possible de supprimer votre dossier. Si vous souhaitez annuler l'instruction contactez votre administration par la messagerie de votre dossier."
        redirect_to dossier_path(dossier)
      end
    end

    def recherche
      @dossier_id = params[:dossier_id]
      dossier = current_user.dossiers.find_by(id: @dossier_id)

      if dossier
        redirect_to url_for_dossier(dossier)
      else
        flash.alert = "Vous n’avez pas de dossier avec le nº #{@dossier_id}."
        redirect_to dossiers_path
      end
    end

    def new
      erase_user_location!

      if params[:brouillon]
        procedure = Procedure.brouillon.find(params[:procedure_id])
      else
        procedure = Procedure.publiees.find(params[:procedure_id])
      end

      dossier = Dossier.create!(procedure: procedure, user: current_user, state: Dossier.states.fetch(:brouillon))

      if dossier.procedure.for_individual
        redirect_to identite_dossier_path(dossier)
      else
        redirect_to siret_dossier_path(id: dossier.id)
      end
    rescue ActiveRecord::RecordNotFound
      flash.alert = t('errors.messages.procedure_not_found')

      redirect_to url_for dossiers_path
    end

    def purge_champ_piece_justificative
      @champ = dossier.champs.find(params[:champ_id])

      @champ.piece_justificative_file.purge_later

      flash.notice = 'La pièce jointe a bien été supprimée.'
    end

    def dossier_for_help
      dossier_id = params[:id] || params[:dossier_id]
      @dossier || (dossier_id.present? && Dossier.find_by(id: dossier_id.to_i))
    end

    private

    def store_user_location!
      store_location_for(:user, request.fullpath)
    end

    def erase_user_location!
      clear_stored_location_for(:user)
    end

    def show_demarche_en_test_banner
      if @dossier.present? && @dossier.procedure.brouillon?
        flash.now.alert = "Ce dossier est déposé sur une démarche en test. Il sera supprimé lors de la publication de la démarche et sa soumission n’a pas de valeur juridique."
      end
    end

    def ensure_dossier_can_be_updated
      if !dossier.can_be_updated_by_user?
        flash.alert = 'Votre dossier ne peut plus être modifié'
        redirect_to dossiers_path
      end
    end

    def page
      [params[:page].to_i, 1].max
    end

    def current_tab(mes_dossiers_count, dossiers_invites_count)
      if dossiers_invites_count == 0
        'mes-dossiers'
      elsif mes_dossiers_count == 0
        'dossiers-invites'
      else
        params[:current_tab].presence || 'mes-dossiers'
      end
    end

    # FIXME: require(:dossier) when all the champs are united
    def champs_params
      params.permit(dossier: {
        champs_attributes: [
          :id, :value, :primary_value, :secondary_value, :piece_justificative_file, value: [],
          champs_attributes: [:id, :_destroy, :value, :primary_value, :secondary_value, :piece_justificative_file, value: []]
        ]
      })
    end

    def dossier
      @dossier ||= Dossier.find(params[:id] || params[:dossier_id])
    end

    def dossier_with_champs
      Dossier.with_champs.find(params[:id])
    end

    def update_dossier_and_compute_errors
      errors = PiecesJustificativesService.upload!(@dossier, current_user, params)

      if champs_params[:dossier] && !@dossier.update(champs_params[:dossier])
        errors += @dossier.errors.full_messages
      end

      if !save_draft?
        errors += @dossier.check_mandatory_champs
        errors += PiecesJustificativesService.missing_pj_error_messages(@dossier)
      end

      errors
    end

    def ensure_ownership!
      if !current_user.owns?(dossier)
        forbidden!
      end
    end

    def ensure_ownership_or_invitation!
      if !current_user.owns_or_invite?(dossier)
        forbidden!
      end
    end

    def forbid_invite_submission!
      if passage_en_construction? && !current_user.owns?(dossier)
        forbidden!
      end
    end

    def forbid_closed_submission!
      if passage_en_construction? && !dossier.can_transition_to_en_construction?
        forbidden!
      end
    end

    def forbidden!
      flash[:alert] = "Vous n'avez pas accès à ce dossier"
      redirect_to root_path
    end

    def render_siret_error(error_message)
      flash.alert = error_message
      render :siret
    end

    def individual_params
      params.require(:individual).permit(:gender, :nom, :prenom, :birthdate)
    end

    def siret_params
      params.require(:user).permit(:siret)
    end

    def commentaire_params
      params.require(:commentaire).permit(:body, :file)
    end

    def passage_en_construction?
      dossier.brouillon? && !save_draft?
    end

    def save_draft?
      dossier.brouillon? && params[:save_draft]
    end
  end
end
