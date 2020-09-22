class Helpscout::FormAdapter
  attr_reader :params

  def self.options
    [
      [I18n.t(TYPE_INFO, scope: [:support, :question]), TYPE_INFO, FAQ_CONTACTER_SERVICE_EN_CHARGE_URL],
      [I18n.t(TYPE_PERDU, scope: [:support, :question]), TYPE_PERDU, LISTE_DES_DEMARCHES_URL],
      [I18n.t(TYPE_INSTRUCTION, scope: [:support, :question]), TYPE_INSTRUCTION, FAQ_OU_EN_EST_MON_DOSSIER_URL],
      [I18n.t(TYPE_AMELIORATION, scope: [:support, :question]), TYPE_AMELIORATION, FEATURE_UPVOTE_URL],
      [I18n.t(TYPE_AUTRE, scope: [:support, :question]), TYPE_AUTRE]
    ]
  end

  def self.admin_options
    [
      [I18n.t(ADMIN_TYPE_QUESTION, scope: [:supportadmin]), ADMIN_TYPE_QUESTION],
      [I18n.t(ADMIN_TYPE_RDV, scope: [:supportadmin]), ADMIN_TYPE_RDV],
      [I18n.t(ADMIN_TYPE_SOUCIS, scope: [:supportadmin]), ADMIN_TYPE_SOUCIS],
      [I18n.t(ADMIN_TYPE_PRODUIT, scope: [:supportadmin]), ADMIN_TYPE_PRODUIT],
      [I18n.t(ADMIN_TYPE_DEMANDE_COMPTE, scope: [:supportadmin]), ADMIN_TYPE_DEMANDE_COMPTE],
      [I18n.t(ADMIN_TYPE_AUTRE, scope: [:supportadmin]), ADMIN_TYPE_AUTRE]
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
    @api.add_tags(conversation_id, params[:tags])
  end

  def create_conversation
    response = @api.create_conversation(
      params[:email],
      params[:subject],
      params[:text],
      params[:file]
    )

    if response.success?
      if params[:phone].present?
        @api.add_phone_number(params[:email], params[:phone])
      end
      response.headers['Resource-ID']
    end
  end
end
