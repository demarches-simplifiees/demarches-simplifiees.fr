class TargetedUserLinksController < ApplicationController
  before_action :set_targeted_user_link, only: [:show]
  def show
    if @targeted_user_link.invalid_signed_in_user?(current_user)
      render
    else
      redirect_to @targeted_user_link.redirect_url(Rails.application.routes.url_helpers)
    end
  end

  private

  def set_targeted_user_link
    @targeted_user_link = TargetedUserLink.find(params[:id])
  end
end
