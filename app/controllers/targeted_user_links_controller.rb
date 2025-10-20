# frozen_string_literal: true

class TargetedUserLinksController < ApplicationController
  def show
    erase_user_location!
    store_user_location! if !user_signed_in?
    if targeted_user_link.invalid_signed_in_user?(current_user)
      render
    else
      redirect_to targeted_user_link.redirect_url(Rails.application.routes.url_helpers, params.permit(:confirmation_token)["confirmation_token"])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, flash: { error: t('errors.messages.targeted_user_link_expired') }
  end

  private

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def erase_user_location!
    clear_stored_location_for(:user)
  end

  def targeted_user_link
    @targeted_user_link ||= TargetedUserLink.find(params[:id])
  end
end
