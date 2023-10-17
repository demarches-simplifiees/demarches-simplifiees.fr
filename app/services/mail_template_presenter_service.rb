class MailTemplatePresenterService
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TextHelper

  delegate :mail_template_for_state, to: :@dossier

  def self.create_commentaire_for_state(dossier)
    service = new(dossier)
    body = ["<p>[#{service.safe_subject}]</p>", service.safe_body].join('')
    CommentaireService.create!(CONTACT_EMAIL, dossier, body: body)
  end

  def safe_body
    sanitize(mail_template_for_state.body_for_dossier(@dossier), scrubber: Sanitizers::MailScrubber.new)
  end

  def safe_subject
    Nokogiri::HTML.parse(truncate(mail_template_for_state.subject_for_dossier(@dossier), length: 100)).text
  end

  def initialize(dossier)
    @dossier = dossier
  end
end
