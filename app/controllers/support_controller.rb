class SupportController < ApplicationController
  invisible_captcha only: [:create], on_spam: :redirect_to_root

  def index
    @form = Helpscout::Form.new(tags: tags_from_query_params, dossier_id: dossier&.id, current_user:)
  end

  def admin
    @form = Helpscout::Form.new(tags: tags_from_query_params, current_user:, for_admin: true)
  end

  def create
    if direct_message? && create_commentaire
      flash.notice = "Votre message a été envoyé sur la messagerie de votre dossier."

      redirect_to messagerie_dossier_path(dossier)
      return
    end

    @form = Helpscout::Form.new(support_form_params.except(:piece_jointe).merge(current_user:))

    if @form.valid?
      create_conversation_later(@form)
      flash.notice = "Votre message a été envoyé."

      redirect_to root_path
    else
      flash.alert = @form.errors.full_messages
      render @form.for_admin ? :admin : :index
    end
  end

  private

  def create_conversation_later(form)
    if support_form_params[:piece_jointe].present?
      blob = ActiveStorage::Blob.create_and_upload!(
        io: support_form_params[:piece_jointe].tempfile,
        filename: support_form_params[:piece_jointe].original_filename,
        content_type: support_form_params[:piece_jointe].content_type,
        identify: false
      ).tap(&:scan_for_virus_later)
    end

    HelpscoutCreateConversationJob.perform_later(
      blob_id: blob&.id,
      subject: form.subject,
      email: current_user&.email || form.email,
      phone: form.phone,
      text: form.text,
      dossier_id: form.dossier_id,
      browser: browser_name,
      tags: form.tags_array
    )
  end

  def create_commentaire
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

  def tags_from_query_params
    support_form_params[:tags]&.join(",") || ""
  end

  def direct_message?
    user_signed_in? && support_form_params[:type] == Helpscout::Form::TYPE_INSTRUCTION && dossier.present? && dossier.messagerie_available?
  end

  def dossier
    @dossier ||= current_user&.dossiers&.find_by(id: support_form_params[:dossier_id])
  end

  def redirect_to_root
    redirect_to root_path, alert: t('invisible_captcha.sentence_for_humans')
  end

  def support_form_params
    keys = [:email, :subject, :text, :type, :dossier_id, :piece_jointe, :phone, :tags, :for_admin]
    if params.key?(:helpscout_form) # submitting form
      params.require(:helpscout_form).permit(*keys)
    else
      params.permit(:dossier_id, tags: []) # prefilling form
    end
  end
end
