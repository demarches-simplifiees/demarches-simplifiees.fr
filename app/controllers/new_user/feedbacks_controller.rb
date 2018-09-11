module NewUser
  class FeedbacksController < UserController
    def create
      current_user.feedbacks.create!(rating: params[:rating])
      flash.notice = "Merci de votre retour, si vous souhaitez nous en dire plus, n'hésitez pas à #{view_context.contact_link('nous contacter', type: Helpscout::FormAdapter::TYPE_AMELIORATION)}."
    end
  end
end
