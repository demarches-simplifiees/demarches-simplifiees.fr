class NewUser::FeedbacksController < ApplicationController
  def create
    current_user.feedbacks.create!(mark: params[:mark])
    flash.notice = "Merci de votre retour, si vous souhaitez nous en dire plus, n'hésitez pas à <a href='mailto:#{CONTACT_EMAIL}' target='_blank'>nous contacter par email</a>."
  end
end
