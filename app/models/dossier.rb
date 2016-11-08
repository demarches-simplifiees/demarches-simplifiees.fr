class Dossier < ActiveRecord::Base
  include SpreadsheetArchitect

  enum state: {draft: 'draft',
               initiated: 'initiated',
               replied: 'replied', #action utilisateur demandé
               updated: 'updated', #etude par l'administration en cours
               validated: 'validated',
               submitted: 'submitted',
               received: 'received',
               closed: 'closed',
               refused: 'refused',
               without_continuation: 'without_continuation'
       }

  has_one :etablissement, dependent: :destroy
  has_one :entreprise, dependent: :destroy
  has_one :individual, dependent: :destroy
  has_many :cerfa, dependent: :destroy

  has_many :pieces_justificatives, dependent: :destroy
  has_many :champs, class_name: 'ChampPublic', dependent: :destroy
  has_many :champs_private, class_name: 'ChampPrivate', dependent: :destroy
  has_many :quartier_prioritaires, dependent: :destroy
  has_many :cadastres, dependent: :destroy
  has_many :commentaires, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :invites_user, class_name: 'InviteUser', dependent: :destroy
  has_many :follows

  belongs_to :procedure
  belongs_to :user

  accepts_nested_attributes_for :individual

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement, allow_nil: true
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champ, to: :procedure
  delegate :france_connect_information, to: :user

  after_save :build_default_champs, if: Proc.new { procedure_id_changed? }
  after_save :build_default_individual, if: Proc.new { procedure.for_individual? }

  validates :user, presence: true

  BROUILLON = %w(draft)
  NOUVEAUX = %w(initiated)
  WAITING_FOR_GESTIONNAIRE = %w(updated)
  WAITING_FOR_USER = %w(replied validated)
  EN_CONSTRUCTION = %w(initiated updated replied)
  VALIDES = %w(validated)
  DEPOSES = %w(submitted)
  EN_INSTRUCTION = %w(submitted received)
  A_INSTRUIRE = %w(received)
  TERMINE = %w(closed refused without_continuation)
  ALL_STATE = %w(draft initiated updated replied validated submitted received closed refused without_continuation)

  def retrieve_last_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def retrieve_all_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).order(created_at: :DESC)
  end

  def build_default_champs
    procedure.types_de_champ.each do |type_de_champ|
      ChampPublic.create(type_de_champ_id: type_de_champ.id, dossier_id: id)
    end

    procedure.types_de_champ_private.each do |type_de_champ|
      ChampPrivate.create(type_de_champ_id: type_de_champ.id, dossier_id: id)
    end
  end

  def build_default_individual
    Individual.new(dossier_id: id).save(validate: false)
  end

  def ordered_champs
    champs.joins(', types_de_champ').where("champs.type_de_champ_id = types_de_champ.id AND types_de_champ.procedure_id = #{procedure.id}").order('order_place')
  end

  def ordered_champs_private
    champs_private.joins(', types_de_champ').where("champs.type_de_champ_id = types_de_champ.id AND types_de_champ.procedure_id = #{procedure.id}").order('order_place')
  end

  def ordered_pieces_justificatives
    champs.joins(', types_de_piece_justificative').where("pieces_justificatives.type_de_piece_justificative_id = types_de_piece_justificative.id AND types_de_piece_justificative.procedure_id = #{procedure.id}").order('order_place ASC')
  end

  def ordered_commentaires
    commentaires.order(created_at: :desc)
  end

  def sous_domaine
    if Rails.env.production?
      'tps'
    else
      'tps-dev'
    end
  end

  def next_step! role, action
    unless %w(initiate follow update comment valid submit receive refuse without_continuation close).include?(action)
      fail 'action is not valid'
    end

    unless %w(user gestionnaire).include?(role)
      fail 'role is not valid'
    end

    if role == 'user'
      case action
        when 'initiate'
          if draft?
            initiated!
          end
        when 'submit'
          if validated?
            submitted!
          end
        when 'update'
          if replied?
            updated!
          end
        when 'comment'
          if replied?
            updated!
          end
      end
    elsif role == 'gestionnaire'
      case action
        when 'comment'
          if updated?
            replied!
          elsif initiated?
            replied!
          end
        when 'follow'
          if initiated?
            updated!
          end
        when 'valid'
          if updated?
            validated!
          elsif replied?
            validated!
          elsif initiated?
            validated!
          end
        when 'receive'
          if submitted?
            received!
          end
        when 'close'
          if received?
            closed!
          end
        when 'refuse'
          if received?
            refused!
          end
        when 'without_continuation'
          if received?
            without_continuation!
          end
      end
    end
    state
  end

  def all_state?
    ALL_STATE.include?(state)
  end

  def brouillon?
    BROUILLON.include?(state)
  end

  def nouveaux?
    NOUVEAUX.include?(state)
  end

  def waiting_for_gestionnaire?
    WAITING_FOR_GESTIONNAIRE.include?(state)
  end

  def waiting_for_user?
    WAITING_FOR_USER.include?(state)
  end

  def en_construction?
    EN_CONSTRUCTION.include?(state)
  end

  def deposes?
    DEPOSES.include?(state)
  end

  def valides?
    VALIDES.include?(state)
  end

  def a_instruire?
    A_INSTRUIRE.include?(state)
  end

  def en_instruction?
    EN_INSTRUCTION.include?(state)
  end

  def termine?
    TERMINE.include?(state)
  end

  def self.all_state order = 'ASC'
    where(state: ALL_STATE, archived: false).order("updated_at #{order}")
  end

  def self.brouillon order = 'ASC'
    where(state: BROUILLON, archived: false).order("updated_at #{order}")
  end

  def self.nouveaux order = 'ASC'
    where(state: NOUVEAUX, archived: false).order("updated_at #{order}")
  end

  def self.waiting_for_gestionnaire order = 'ASC'
    where(state: WAITING_FOR_GESTIONNAIRE, archived: false).order("updated_at #{order}")
  end

  def self.waiting_for_user order = 'ASC'
    where(state: WAITING_FOR_USER, archived: false).order("updated_at #{order}")
  end

  def self.en_construction order = 'ASC'
    where(state: EN_CONSTRUCTION, archived: false).order("updated_at #{order}")
  end

  def self.valides order = 'ASC'
    where(state: VALIDES, archived: false).order("updated_at #{order}")
  end

  def self.deposes order = 'ASC'
    where(state: DEPOSES, archived: false).order("updated_at #{order}")
  end

  def self.a_instruire order = 'ASC'
    where(state: A_INSTRUIRE, archived: false).order("updated_at #{order}")
  end

  def self.en_instruction order = 'ASC'
    where(state: EN_INSTRUCTION, archived: false).order("updated_at #{order}")
  end

  def self.termine order = 'ASC'
    where(state: TERMINE, archived: false).order("updated_at #{order}")
  end

  def self.search current_gestionnaire, terms
    return [] if terms.blank?

    dossiers = Dossier.arel_table
    users = User.arel_table
    etablissements = Etablissement.arel_table
    entreprises = Entreprise.arel_table

    composed_scope = self.joins('LEFT OUTER JOIN users ON users.id = dossiers.user_id')
                         .joins('LEFT OUTER JOIN entreprises ON entreprises.dossier_id = dossiers.id')
                         .joins('LEFT OUTER JOIN etablissements ON etablissements.dossier_id = dossiers.id')

    terms.split.each do |word|
      query_string = "%#{word}%"
      query_string_start_with = "#{word}%"

      composed_scope = composed_scope.where(
          users[:email].matches(query_string).or\
          etablissements[:siret].matches(query_string_start_with).or\
          entreprises[:raison_sociale].matches(query_string).or\
          dossiers[:id].eq(word_is_an_integer word))
    end

    composed_scope = composed_scope.where(
        dossiers[:id].eq_any(current_gestionnaire.dossiers.ids).and\
        dossiers[:state].does_not_match('draft').and\
        dossiers[:archived].eq(false))

    composed_scope
  end

  def cerfa_available?
    procedure.cerfa_flag? && cerfa.size != 0
  end

  def convert_specific_values_to_string(hash_to_convert)
    hash = {}
    hash_to_convert.each do |key, value|
      value = value.to_s if !value.kind_of?(Time) && !value.nil?
      hash.store(key, value)
    end
    return hash
  end

  def as_csv(options={})
    dossier_attr = DossierSerializer.new(self).attributes
    dossier_attr = convert_specific_values_to_string(dossier_attr)
    unless entreprise.nil?
      etablissement_attr = EtablissementCsvSerializer.new(self.etablissement).attributes.map { |k, v| ["etablissement.#{k}".parameterize.underscore.to_sym, v] }.to_h
      entreprise_attr = EntrepriseSerializer.new(self.entreprise).attributes.map { |k, v| ["entreprise.#{k}".parameterize.underscore.to_sym, v] }.to_h
    else
      etablissement_attr = EtablissementSerializer.new(Etablissement.new).attributes.map { |k, v| ["etablissement.#{k}".parameterize.underscore.to_sym, v] }.to_h
      entreprise_attr = EntrepriseSerializer.new(Entreprise.new).attributes.map { |k, v| ["entreprise.#{k}".parameterize.underscore.to_sym, v] }.to_h
    end
    dossier_attr = dossier_attr.merge(convert_specific_values_to_string(etablissement_attr)).merge(convert_specific_values_to_string(entreprise_attr))

    dossier_attr
  end

  def spreadsheet_columns
    self.as_csv.to_a
  end

  def reset!
    etablissement.destroy
    entreprise.destroy

    update_attributes(autorisation_donnees: false)
  end

  def total_follow
    follows.size
  end

  def total_commentaire
    self.commentaires.size
  end

  def submit!
    self.deposit_datetime= DateTime.now

    next_step! 'user', 'submit'
    NotificationMailer.dossier_submitted(self).deliver_now!
  end

  def read_only?
    validated? || received? || submitted? || closed? || refused? || without_continuation?
  end

  def owner? email
    user.email == email
  end

  def invite_by_user? email
    (invites_user.pluck :email).include? email
  end

  def self.word_is_an_integer word
    return 0 if Float(word) > 2147483647

    Float(word)
  rescue ArgumentError
    0
  end
end
