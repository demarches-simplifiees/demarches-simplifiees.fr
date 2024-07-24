class Helpscout::Form
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :email, :string
  attribute :subject, :string
  attribute :text, :string
  attribute :type, :string
  attribute :dossier_id, :integer
  attribute :tags, :string
  attribute :phone, :string
  attribute :tags, :string
  attribute :for_admin, :boolean, default: false

  validates :email, presence: true, strict_email: true, if: :require_email? # i18n-tasks-use t('activemodel.errors.models.helpscout/form.invalid_email_format')
  validates :subject, presence: true
  validates :text, presence: true
  validates :type, presence: true

  attr_reader :current_user
  attr_reader :options

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
      [I18n.t(:question, scope: [:support, :index, TYPE_INFO]), TYPE_INFO, I18n.t("links.common.faq.contacter_service_en_charge_url")],
      [I18n.t(:question, scope: [:support, :index, TYPE_PERDU]), TYPE_PERDU, LISTE_DES_DEMARCHES_URL],
      [I18n.t(:question, scope: [:support, :index, TYPE_INSTRUCTION]), TYPE_INSTRUCTION, I18n.t("links.common.faq.ou_en_est_mon_dossier_url")],
      [I18n.t(:question, scope: [:support, :index, TYPE_AMELIORATION]), TYPE_AMELIORATION, FEATURE_UPVOTE_URL],
      [I18n.t(:question, scope: [:support, :index, TYPE_AUTRE]), TYPE_AUTRE]
    ]
  end

  def self.admin_options
    [
      [I18n.t(:question, scope: [:support, :admin, ADMIN_TYPE_QUESTION], app_name: Current.application_name), ADMIN_TYPE_QUESTION],
      [I18n.t(:question, scope: [:support, :admin, ADMIN_TYPE_RDV], app_name: Current.application_name), ADMIN_TYPE_RDV],
      [I18n.t(:question, scope: [:support, :admin, ADMIN_TYPE_SOUCIS], app_name: Current.application_name), ADMIN_TYPE_SOUCIS],
      [I18n.t(:question, scope: [:support, :admin, ADMIN_TYPE_PRODUIT]), ADMIN_TYPE_PRODUIT],
      [I18n.t(:question, scope: [:support, :admin, ADMIN_TYPE_DEMANDE_COMPTE]), ADMIN_TYPE_DEMANDE_COMPTE],
      [I18n.t(:question, scope: [:support, :admin, ADMIN_TYPE_AUTRE]), ADMIN_TYPE_AUTRE]
    ]
  end

  def initialize(params)
    @current_user = params.delete(:current_user)
    params[:email] = EmailSanitizableConcern::EmailSanitizer.sanitize(params[:email]) if params[:email].present?
    super(params)

    @options = if for_admin?
      self.class.admin_options
    else
      self.class.default_options
    end
  end

  alias for_admin? for_admin

  def tags_array
    (tags&.split(",") || []) + ['contact form', type]
  end

  def require_email? = current_user.blank?

  def persisted? = false
end
