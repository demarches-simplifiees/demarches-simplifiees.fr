# frozen_string_literal: true

class MailTemplatePresenterService
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TextHelper
  include ChampHelper

  def self.create_commentaire_for_state(dossier, state)
    if dossier.procedure.accuse_lecture? && Dossier::TERMINE.include?(state)
      CommentaireService.create!(CONTACT_EMAIL, dossier, body: I18n.t('layouts.mailers.accuse_lecture.commentaire_html', service: dossier.procedure.service&.nom))
    else
      service = new(dossier, state)
      body = ["<p>[#{service.safe_subject}]</p>", service.safe_body].join('')
      CommentaireService.create!(CONTACT_EMAIL, dossier, body: body)
    end
  end

  def safe_body
    format_text_value(@email_template.body_for_dossier(@dossier))
  end

  def safe_subject
    Nokogiri::HTML.parse(truncate(@email_template.subject_for_dossier(@dossier), length: 100)).text
  end

  def initialize(dossier, state)
    @dossier = dossier
    @email_template = dossier.email_template_for(state)
  end
end
