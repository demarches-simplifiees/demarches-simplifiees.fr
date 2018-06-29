class Users::DescriptionController < UsersController
  before_action only: [:show] do
    authorized_routes? self.class
  end

  before_action :check_autorisation_donnees, only: [:show]
  before_action :check_starter_dossier_informations, only: [:show]

  def show
    @dossier ||= current_user_dossier.decorate

    @procedure = @dossier.procedure
    @champs = @dossier.ordered_champs

    @headers = @champs.select { |c| c.type_champ == 'header_section' }

    if !@dossier.can_be_en_construction?
      flash[:alert] = t('errors.messages.procedure_archived')
    end

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  def update
    dossier = current_user_dossier
    procedure = dossier.procedure

    return head :forbidden if !dossier.can_be_en_construction?

    ChampsService.save_champs(dossier.champs, params) if params[:champs]

    errors_upload = PiecesJustificativesService.upload!(dossier, current_user, params) + ChampsService.check_piece_justificative_files(dossier.champs)
    return redirect_to_description_with_errors(dossier, errors_upload) if errors_upload.any?

    if params[:champs] && !(brouillon_submission? || brouillon_then_dashboard_submission?)
      errors =
        ChampsService.build_error_messages(dossier.champs) +
        PiecesJustificativesService.missing_pj_error_messages(dossier)
      return redirect_to_description_with_errors(dossier, errors) if errors.any?
    end

    if brouillon_submission?
      flash.notice = 'Votre brouillon a bien été sauvegardé.'
      redirect_to users_dossier_description_path(dossier.id)
    elsif brouillon_then_dashboard_submission?
      redirect_to url_for(controller: :dossiers, action: :index, liste: :brouillon)
    else
      if dossier.brouillon?
        dossier.en_construction!
        # TODO move to model
        NotificationMailer.send_initiated_notification(dossier).deliver_later
      end
      flash.notice = 'Félicitations, votre demande a bien été enregistrée.'
      redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: dossier.id)
    end
  end

  def pieces_justificatives
    invite = current_user.invite? params[:dossier_id]

    @dossier ||= Dossier.find(params[:dossier_id]) if invite
    @dossier ||= current_user_dossier

    if (errors_upload = PiecesJustificativesService.upload!(@dossier, current_user, params)).present?
      if flash.alert.nil?
        flash.alert = errors_upload
      else
        flash.alert = [flash.alert] + errors_upload
      end

    else
      flash.notice = 'Nouveaux fichiers envoyés' if flash.alert.nil?
    end

    return redirect_to users_dossiers_invite_path(id: current_user.invites.find_by(dossier_id: @dossier.id).id) if invite

    redirect_to users_dossier_recapitulatif_path
  end

  def self.route_authorization
    {
      states: [:brouillon, :en_construction]
    }
  end

  private

  def redirect_to_description_with_errors(dossier, errors)
    errors_to_display = if errors.count > 3
      errors.take(3) + ['...']
    else
      errors
    end

    flash.alert = errors_to_display
    redirect_to users_dossier_description_path(dossier_id: dossier.id)
  end

  def brouillon_submission?
    params[:submit_action] == 'brouillon'
  end

  def brouillon_then_dashboard_submission?
    params[:submit_action] == 'brouillon_then_dashboard'
  end

  def check_autorisation_donnees
    @dossier = current_user_dossier

    redirect_to url_for(users_dossier_path(@dossier.id)) if @dossier.autorisation_donnees.nil? || !@dossier.autorisation_donnees
  end

  def check_starter_dossier_informations
    @dossier ||= current_user_dossier

    if (@dossier.procedure.for_individual? && @dossier.individual.nil?) ||
        (!@dossier.procedure.for_individual? && @dossier.etablissement.nil?)
      redirect_to url_for(users_dossier_path(@dossier.id))
    end
  end
end
