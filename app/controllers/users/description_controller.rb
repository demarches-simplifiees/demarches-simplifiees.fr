class Users::DescriptionController < UsersController
  before_action only: [:show] do
    authorized_routes? self.class
  end

  def show
    @dossier = current_user_dossier.decorate

    @procedure = @dossier.procedure
    @champs = @dossier.ordered_champs

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  def error
    show
    flash.now.alert = 'Un ou plusieurs attributs obligatoires sont manquants ou incorrects.'
    render 'show'
  end

  def create
    @dossier = current_user_dossier
    @procedure = @dossier.procedure
    @champs = @dossier.ordered_champs

    unless @dossier.update_attributes(create_params)
      @dossier = @dossier.decorate

      flash.now.alert = @dossier.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end

    if @procedure.cerfa_flag?
      unless params[:cerfa_pdf].nil?
        cerfa = Cerfa.new(content: params[:cerfa_pdf], dossier: @dossier, user: current_user)
        unless cerfa.save
          flash.now.alert = cerfa.errors.full_messages.join('<br />').html_safe
          return render 'show'
        end
      end
    end

    unless params[:champs].nil?
      champs_service_errors = ChampsService.save_formulaire @dossier.champs, params

      unless champs_service_errors.empty?
        flash.now.alert = (champs_service_errors.inject('') {|acc, error| acc+= error[:message]+'<br>' }).html_safe
        return render 'show'
      end
    end

    unless (errors_upload = PiecesJustificativesService.upload!(@dossier, current_user, params)).empty?
      flash.alert = errors_upload.html_safe
      return render 'show'
    end

    if @dossier.draft?
      @dossier.initiated!
    end

    flash.notice = 'Félicitation, votre demande a bien été enregistrée.'
    redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: @dossier.id)
  end

  def pieces_justificatives
    invite = current_user.invite? params[:dossier_id]

    @dossier ||= Dossier.find(params[:dossier_id]) if invite
    @dossier ||= current_user_dossier

    if !((errors_upload = PiecesJustificativesService.upload!(@dossier, current_user, params)).empty?)
      flash.alert = errors_upload.html_safe
    else
      flash.notice = 'Nouveaux fichiers envoyés'
    end

    return redirect_to users_dossiers_invite_path(id: current_user.invites.find_by_dossier_id(@dossier.id).id) if invite

    redirect_to users_dossier_recapitulatif_path
  end

  def self.route_authorization
    {
        states: [:draft, :initiated, :replied, :updated]
    }
  end

  private

  def create_params
    params.permit()
  end
end
