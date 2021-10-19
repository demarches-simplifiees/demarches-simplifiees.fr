module Users
  class ProfilController < UserController
    def show
      @waiting_transfers = current_user.dossiers.joins(:transfer).group('dossier_transfers.email').count.to_a
    end

    def renew_api_token
      @token = current_administrateur.renew_api_token
      flash.now.notice = 'Votre jeton a été regénéré.'
      render :show
    end

    def update_email
      if current_user.instructeur? && !target_email_allowed?
        flash.alert = t('.email_not_allowed', contact_email: CONTACT_EMAIL, requested_email: requested_email)
      elsif current_user.update(update_email_params)
        flash.notice = t('devise.registrations.update_needs_confirmation')
      elsif current_user.errors&.details&.dig(:email)&.any? { |e| e[:error] == :taken }
        UserMailer.account_already_taken(current_user, requested_email).deliver_later
        # avoid leaking information about whether an account with this email exists or not
        flash.notice = t('devise.registrations.update_needs_confirmation')
      else
        flash.alert = current_user.errors.full_messages
      end

      redirect_to profil_path
    end

    def transfer_all_dossiers
      DossierTransfer.initiate(next_owner_email, current_user.dossiers)
      flash.notice = t('.new_transfer', count: current_user.dossiers.count, email: next_owner_email)
      redirect_to profil_path
    end

    private

    def update_email_params
      params.require(:user).permit(:email)
    end

    def requested_email
      update_email_params[:email]
    end

    def target_email_allowed?
      LEGIT_ADMIN_DOMAINS.any? { |d| requested_email.end_with?(d) }
    end

    def next_owner_email
      params[:next_owner]
    end
  end
end
