class Dossier < ActiveRecord::Base

  enum state: {draft: 'draft',
               initiated: 'initiated',
               replied: 'replied',
               updated: 'updated',
               validated: 'validated',
               submitted: 'submitted',
               closed: 'closed'}

  has_one :etablissement, dependent: :destroy
  has_one :entreprise, dependent: :destroy
  has_many :cerfa, dependent: :destroy

  has_many :pieces_justificatives, dependent: :destroy
  has_many :champs, dependent: :destroy
  has_many :quartier_prioritaires, dependent: :destroy
  has_many :cadastres, dependent: :destroy
  has_many :commentaires, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :follows

  belongs_to :procedure
  belongs_to :user

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement, allow_nil: true
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champ, to: :procedure

  after_save :build_default_champs, if: Proc.new { procedure_id_changed? }

  validates :user, presence: true

  WAITING_FOR_GESTIONNAIRE = %w(initiated updated submitted)
  WAITING_FOR_USER = %w(replied validated)
  TERMINE = %w(closed)

  def retrieve_last_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def retrieve_all_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).order(created_at: :DESC)
  end

  def build_default_champs
    procedure.types_de_champ.each do |type_de_champ|
      Champ.create(type_de_champ_id: type_de_champ.id, dossier_id: id)
    end
  end

  def ordered_champs
    champs.joins(', types_de_champ').where("champs.type_de_champ_id = types_de_champ.id AND types_de_champ.procedure_id = #{procedure.id}").order('order_place')
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
    unless %w(initiate update comment valid submit close).include?(action)
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
        when 'valid'
          if updated?
            validated!
          elsif replied?
            validated!
          elsif initiated?
            validated!
          end
        when 'close'
          if submitted?
            closed!
          end
      end
    end
    state
  end

  def waiting_for_gestionnaire?
    WAITING_FOR_GESTIONNAIRE.include?(state)
  end

  def waiting_for_user?
    WAITING_FOR_USER.include?(state)
  end

  def termine?
    TERMINE.include?(state)
  end

  def self.waiting_for_gestionnaire order = 'ASC'
    where(state: WAITING_FOR_GESTIONNAIRE, archived: false).order("updated_at #{order}")
  end

  def self.waiting_for_user order = 'ASC'
    where(state: WAITING_FOR_USER, archived: false).order("updated_at #{order}")
  end

  def self.termine order = 'ASC'
    where(state: TERMINE, archived: false).order("updated_at #{order}")
  end

  def self.search current_gestionnaire, terms
    return [], nil if terms.blank?

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
          entreprises[:raison_sociale].matches(query_string))
    end

    #TODO refactor
    composed_scope = composed_scope.where(
        dossiers[:id].eq_any(current_gestionnaire.dossiers_filter.ids).and\
        dossiers[:state].does_not_match('draft').and\
        dossiers[:archived].eq(false))

    begin
      if Float(terms) && terms.to_i <= 2147483647 && current_gestionnaire.dossiers_filter.ids.include?(terms.to_i)
        dossier = Dossier.where("state != 'draft'").find(terms.to_i)
      end
    rescue ArgumentError, ActiveRecord::RecordNotFound
      dossier = nil
    end

    return composed_scope, dossier
  end

  def cerfa_available?
    procedure.cerfa_flag? && cerfa.size != 0
  end

  def as_csv(options={})
    dossier_attr = DossierSerializer.new(self).attributes
    etablissement_attr = EtablissementCsvSerializer.new(self.etablissement).attributes.map {|k, v| ["etablissement.#{k}", v] }.to_h
    entreprise_attr = EntrepriseSerializer.new(self.entreprise).attributes.map {|k, v| ["entreprise.#{k}", v] }.to_h
    dossier_attr.merge(etablissement_attr).merge(entreprise_attr)
  end

  def reset!
    entreprise.destroy unless entreprise.nil?

    update_attributes(autorisation_donnees: false)
  end

  def total_follow
    follows.size
  end
end
