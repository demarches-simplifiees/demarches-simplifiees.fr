# frozen_string_literal: true

class ContactForm < ApplicationRecord
  attr_reader :options

  belongs_to :user, optional: true

  after_initialize :set_options
  before_validation :normalize_strings
  before_validation :sanitize_email
  before_save :add_default_tags

  validates :email, presence: true, strict_email: true, if: :require_email?
  validates :subject, presence: true
  validates :text, presence: true
  validates :question_type, presence: true

  has_one_attached :piece_jointe

  TYPE_INFO = 'procedure_info'
  TYPE_PERDU = 'lost_user'
  TYPE_INSTRUCTION = 'instruction_info'
  TYPE_AMELIORATION = 'product'
  TYPE_AUTRE = 'other'

  ADMIN_TYPE_RDV = 'admin_demande_rdv'
  ADMIN_TYPE_QUESTION = 'admin_question'
  ADMIN_TYPE_SOUCIS = 'admin_soucis'
  ADMIN_TYPE_PRODUIT = 'admin_suggestion_produit'
  ADMIN_TYPE_DEMANDE_COMPTE = 'admin_demande_compte'
  ADMIN_TYPE_AUTRE = 'admin_autre'

  def self.default_options
    [
      [I18n.t(:question, scope: [:contact, :index, TYPE_INFO]), TYPE_INFO, I18n.t("links.common.faq.contacter_service_en_charge_url")],
      [I18n.t(:question, scope: [:contact, :index, TYPE_PERDU]), TYPE_PERDU, LISTE_DES_DEMARCHES_URL],
      [I18n.t(:question, scope: [:contact, :index, TYPE_INSTRUCTION]), TYPE_INSTRUCTION, I18n.t("links.common.faq.ou_en_est_mon_dossier_url")],
      [I18n.t(:question, scope: [:contact, :index, TYPE_AMELIORATION]), TYPE_AMELIORATION, FEATURE_UPVOTE_URL],
      [I18n.t(:question, scope: [:contact, :index, TYPE_AUTRE]), TYPE_AUTRE]
    ]
  end

  def self.admin_options
    [
      [I18n.t(:question, scope: [:contact, :admin, ADMIN_TYPE_QUESTION], app_name: Current.application_name), ADMIN_TYPE_QUESTION],
      [I18n.t(:question, scope: [:contact, :admin, ADMIN_TYPE_RDV], app_name: Current.application_name), ADMIN_TYPE_RDV],
      [I18n.t(:question, scope: [:contact, :admin, ADMIN_TYPE_SOUCIS], app_name: Current.application_name), ADMIN_TYPE_SOUCIS],
      [I18n.t(:question, scope: [:contact, :admin, ADMIN_TYPE_PRODUIT]), ADMIN_TYPE_PRODUIT],
      [I18n.t(:question, scope: [:contact, :admin, ADMIN_TYPE_DEMANDE_COMPTE]), ADMIN_TYPE_DEMANDE_COMPTE],
      [I18n.t(:question, scope: [:contact, :admin, ADMIN_TYPE_AUTRE]), ADMIN_TYPE_AUTRE]
    ]
  end

  def for_admin=(value)
    super(value)
    set_options
  end

  def create_conversation_later
    if user.present? && Flipper.enabled?(:contact_crisp, user)
      CrispCreateConversationJob.perform_later(self)
    else
      HelpscoutCreateConversationJob.perform_later(self)
    end
  end

  def require_email? = user.blank?

  private

  def normalize_strings
    self.subject = subject&.strip
    self.text = text&.strip
  end

  def sanitize_email
    self.email = EmailSanitizableConcern::EmailSanitizer.sanitize(email) if email.present?
  end

  def add_default_tags
    self.tags = tags.push('contact form', question_type).uniq
  end

  def set_options
    @options = for_admin? ? self.class.admin_options : self.class.default_options
  end
end
