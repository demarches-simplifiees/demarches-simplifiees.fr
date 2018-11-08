class SupportController < ApplicationController
  layout "new_application"

  def index
    setup_context
  end

  def create
    if direct_message? && create_commentaire
      flash.notice = "Votre message a été envoyé sur la messagerie de votre dossier."

      redirect_to messagerie_dossier_path(dossier)
    elsif create_conversation
      flash.notice = "Votre message a été envoyé."

      redirect_to root_path(formulaire_contact_general_submitted: true)
    else
      setup_context
      flash.now.alert = "Une erreur est survenue. Vous pouvez nous contacter à #{helpers.mail_to(CONTACT_EMAIL)}."

      render :index
    end
  end

  private

  def setup_context
    @dossier_id = dossier&.id
    @tags = tags
    @options = Helpscout::FormAdapter::OPTIONS
  end

  def create_conversation
    Helpscout::FormAdapter.new(
      subject: params[:subject],
      email: email,
      text: params[:text],
      file: params[:file],
      dossier_id: dossier&.id,
      browser: browser_name,
      tags: tags
    ).send_form
  end

  def create_commentaire
    dossier.commentaires.create(
      email: email,
      file: params[:file],
      body: "[#{params[:subject]}]<br><br>#{params[:text]}"
    )
  end

  def tags
    [params[:tags], params[:type]].flatten.compact
      .map { |tag| tag.split(',') }
      .flatten
      .reject(&:blank?).uniq
  end

  def browser_name
    if browser.known?
      "#{browser.name} #{browser.version} (#{browser.platform.name})"
    end
  end

  def direct_message?
    user_signed_in? && params[:type] == Helpscout::FormAdapter::TYPE_INSTRUCTION && dossier.present? && !dossier.brouillon?
  end

  def dossier
    @dossier ||= current_user&.dossiers&.find_by(id: params[:dossier_id])
  end

  def email
    logged_user ? logged_user.email : params[:email]
  end
end
