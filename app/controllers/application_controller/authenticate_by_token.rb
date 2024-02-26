module ApplicationController::AuthenticateByToken
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_by_token!

    protected

    def authenticate_by_token!
      return if params[:authenticable_token].blank?

      user = User.find_by_authenticable_token(params[:authenticable_token])

      if user.present?
        user.clear_sign_in_secret!
        sign_in(user)
      end

      # Don't let the token in url, wheter authentication was successfull or not
      # If not authenticated, next request will redirect to signin with notice
      redirect_to url_for(params.except(:authenticable_token).to_unsafe_h), status: 302
    end
  end
end
