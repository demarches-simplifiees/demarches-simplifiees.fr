class NewUser::FeedbacksController < ApplicationController
  def create
    current_user.feedbacks.create!(mark: params[:mark])
    flash.notice = "Merci de votre retour"
  end
end
