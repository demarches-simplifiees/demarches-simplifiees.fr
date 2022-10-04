class TargetedUserLinksController < ApplicationController
  def show
    if targeted_user_link.invalid_signed_in_user?(current_user)
      render
    else
      redirect_to targeted_user_link.redirect_url(Rails.application.routes.url_helpers)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, flash: { error: t('errors.messages.targeted_user_link_expired') }
  end

  private

  def targeted_user_link
    @targeted_user_link ||= TargetedUserLink.find(params[:id])
  end
end
