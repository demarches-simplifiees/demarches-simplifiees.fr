class SupportController < ApplicationController
  invisible_captcha only: [:create], on_spam: :redirect_to_root

  def index
    @form = ContactForm.new(tags: support_form_params.fetch(:tags, []), dossier_id: dossier&.id)
    @form.user = current_user
  end

  def admin
    @form = ContactForm.new(tags: support_form_params.fetch(:tags, []), for_admin: true)
    @form.user = current_user
  end

  def create
    if direct_message?
      create_commentaire!
      flash.notice = t('.direct_message_sent')

      redirect_to messagerie_dossier_path(dossier)
      return
    end

    form_params = support_form_params
    @form = ContactForm.new(form_params.except(:piece_jointe))
    @form.piece_jointe.attach(form_params[:piece_jointe]) if form_params[:piece_jointe].present?
    @form.user = current_user

    if @form.save
      @form.create_conversation_later
      flash.notice = t('.message_sent')

      redirect_to root_path
    else
      flash.alert = @form.errors.full_messages
      render @form.for_admin ? :admin : :index
    end
  end

  private

  def create_commentaire!
    attributes = {
      piece_jointe: support_form_params[:piece_jointe],
      body: "[#{support_form_params[:subject]}]<br><br>#{support_form_params[:text]}"
    }
    CommentaireService.create!(current_user, dossier, attributes)
  end

  def browser_name
    if browser.known?
      "#{browser.name} #{browser.version} (#{browser.platform.name})"
    end
  end

  def direct_message?
    return false unless user_signed_in?
    return false unless support_form_params[:question_type] == ContactForm::TYPE_INSTRUCTION

    dossier&.messagerie_available?
  end

  def dossier
    @dossier ||= current_user&.dossiers&.find_by(id: support_form_params[:dossier_id])
  end

  def redirect_to_root
    redirect_to root_path, alert: t('invisible_captcha.sentence_for_humans')
  end

  def support_form_params
    keys = [:email, :subject, :text, :question_type, :dossier_id, :piece_jointe, :phone, :for_admin, tags: []]
    if params.key?(:contact_form) # submitting form
      params.require(:contact_form).permit(*keys)
    else
      params.permit(:dossier_id, tags: []) # prefilling form
    end
  end
end
