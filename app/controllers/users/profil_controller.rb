module Users
  class ProfilController < UserController
    def show
    end

    def renew_api_token
      @token = current_administrateur.renew_api_token
      flash.now.notice = 'Votre jeton a été regénéré.'
      render :show
    end
  end
end
