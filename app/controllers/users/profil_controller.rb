module Users
  class ProfilController < UserController
    def show
    end

    def renew_api_token
      @token = current_administrateur.renew_api_token
      flash.now.notice = 'Votre jeton a été regénéré.'
      render :show
    end

    def update_email
      if @current_user.update(update_email_params)
        flash.notice = t('devise.registrations.update_needs_confirmation')
      # to avoid leaking who has signed in
      elsif @current_user.errors&.details&.dig(:email)&.any? { |e| e[:error] == :taken }
        flash.notice = t('devise.registrations.update_needs_confirmation')
      else
        flash.alert = @current_user.errors.full_messages
      end

      redirect_to profil_path
    end

    private

    def update_email_params
      params.require(:user).permit(:email)
    end
  end
end
