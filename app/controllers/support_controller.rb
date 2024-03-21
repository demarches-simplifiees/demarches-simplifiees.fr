class SupportController < ApplicationController
  invisible_captcha only: [:create], on_spam: :redirect_to_root

  def index
    setup_context
  end

  def admin
    setup_context_admin
  end

  def create
    if direct_message? && create_commentaire
      flash.notice = "Votre message a été envoyé sur la messagerie de votre dossier."

      redirect_to messagerie_dossier_path(dossier)
    elsif create_conversation
      flash.notice = "Votre message a été envoyé."

      if params[:admin]
        redirect_to root_path(formulaire_contact_admin_submitted: true)
      else
        redirect_to root_path(formulaire_contact_general_submitted: true)
      end
    else
      flash.now.alert = "Une erreur est survenue. Vous pouvez nous contacter à #{helpers.mail_to(Current.contact_email)}."

      if params[:admin]
        setup_context_admin
        render :admin
      else
        setup_context
        render :index
      end
    end
  end

  private

  def setup_context
    @dossier_id = dossier&.id
    @tags = tags
    @options = Helpscout::FormAdapter.options
  end

  def setup_context_admin
    @tags = tags
    @options = Helpscout::FormAdapter.admin_options
  end

  def create_conversation
    Helpscout::FormAdapter.new(
      subject: params[:subject],
      email: email,
      phone: params[:phone],
      text: params[:text],
      file: params[:piece_jointe],
      dossier_id: dossier&.id,
      browser: browser_name,
      tags: tags
    ).send_form
  end

  def create_commentaire
    attributes = {
      piece_jointe: params[:piece_jointe],
      body: "[#{params[:subject]}]<br><br>#{params[:text]}"
    }
    CommentaireService.create!(current_user, dossier, attributes)
  end

  def tags
    [params[:tags], params[:type]].flatten.compact
      .map { |tag| tag.split(',') }
      .flatten
      .compact_blank.uniq
  end

  def browser_name
    if browser.known?
      "#{browser.name} #{browser.version} (#{browser.platform.name})"
    end
  end

  def direct_message?
    user_signed_in? && params[:type] == Helpscout::FormAdapter::TYPE_INSTRUCTION && dossier.present? && dossier.messagerie_available?
  end

  def dossier
    @dossier ||= current_user&.dossiers&.find_by(id: params[:dossier_id])
  end

  def email
    current_user&.email || params[:email]
  end

  def redirect_to_root
    redirect_to root_path, alert: t('invisible_captcha.sentence_for_humans')
  end
end
