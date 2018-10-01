class Users::DescriptionController < UsersController
  def pieces_justificatives
    invite = current_user.invite? params[:dossier_id]

    if invite
      @dossier ||= Dossier.find(params[:dossier_id])
    end

    @dossier ||= current_user_dossier

    if (errors_upload = PiecesJustificativesService.upload!(@dossier, current_user, params)).present?
      if flash.alert.nil?
        flash.alert = errors_upload
      else
        flash.alert = [flash.alert] + errors_upload
      end

    else
      if flash.alert.nil?
        flash.notice = 'Nouveaux fichiers envoyés'
      end
    end

    if invite
      return redirect_to users_dossiers_invite_path(id: current_user.invites.find_by(dossier_id: @dossier.id).id)
    end

    redirect_to users_dossier_recapitulatif_path
  end
end
