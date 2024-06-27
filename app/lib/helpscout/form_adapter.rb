class Helpscout::FormAdapter
  attr_reader :params

  def self.options
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

  def initialize(params = {}, api = nil)
    @params = params
    @api = api || Helpscout::API.new
  end

  TYPE_INFO = 'procedure_info'
  TYPE_PERDU = 'lost_user'
  TYPE_INSTRUCTION = 'instruction_info'
  TYPE_AMELIORATION = 'product'
  TYPE_AUTRE = 'other'

  ADMIN_TYPE_RDV = 'admin demande rdv'
  ADMIN_TYPE_QUESTION = 'admin question'
  ADMIN_TYPE_SOUCIS = 'admin soucis'
  ADMIN_TYPE_PRODUIT = 'admin suggestion produit'
  ADMIN_TYPE_DEMANDE_COMPTE = 'admin demande compte'
  ADMIN_TYPE_AUTRE = 'admin autre'

  def send_form
    conversation_id = create_conversation

    if conversation_id.present?
      add_tags(conversation_id)
      true
    else
      false
    end
  end

  private

  def add_tags(conversation_id)
    @api.add_tags(conversation_id, tags)
  end

  def tags
    (params[:tags].presence || []) + ['contact form']
  end

  def create_conversation
    response = @api.create_conversation(
      params[:email],
      params[:subject],
      params[:text],
      params[:blob]
    )

    if response.success?
      if params[:phone].present?
        @api.add_phone_number(params[:email], params[:phone])
      end
      response.headers['Resource-ID']
    else
      raise StandardError, "Error while creating conversation: #{response.response_code} '#{response.body}'"
    end
  end
end
