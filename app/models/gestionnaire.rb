class Gestionnaire < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :administrateurs

  has_one :preference_smart_listing_page, dependent: :destroy

  has_many :assign_to, dependent: :destroy
  has_many :procedures, through: :assign_to
  has_many :dossiers, -> { where.not(state: :draft) }, through: :procedures
  has_many :followed_dossiers, through: :follows, source: :dossier
  has_many :follows
  has_many :preference_list_dossiers
  has_many :avis

  after_create :build_default_preferences_list_dossier
  after_create :build_default_preferences_smart_listing_page

  include CredentialsSyncableConcern

  def procedure_filter
    return nil unless assign_to.pluck(:procedure_id).include?(self[:procedure_filter])

    self[:procedure_filter]
  end

  def can_view_dossier?(dossier_id)
    avis.where(dossier_id: dossier_id).any? ||
      dossiers.where(id: dossier_id).any?
  end

  def toggle_follow_dossier dossier_id
    dossier = dossier_id
    dossier = Dossier.find(dossier_id) unless dossier_id.class == Dossier

    Follow.create!(dossier: dossier, gestionnaire: self)
  rescue ActiveRecord::RecordInvalid
    Follow.where(dossier: dossier, gestionnaire: self).delete_all
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def follow? dossier_id
    dossier_id = dossier_id.id if dossier_id.class == Dossier

    Follow.where(gestionnaire_id: id, dossier_id: dossier_id).any?
  end

  def assigned_on_procedure?(procedure_id)
    procedures.find_by(id: procedure_id).present?
  end

  def build_default_preferences_list_dossier procedure_id=nil

    PreferenceListDossier.available_columns_for(procedure_id).each do |table|
      table.second.each do |column|

        if valid_couple_table_attr? table.first, column.first
          PreferenceListDossier.create(
              libelle: column.second[:libelle],
              table: column.second[:table],
              attr: column.second[:attr],
              attr_decorate: column.second[:attr_decorate],
              bootstrap_lg: column.second[:bootstrap_lg],
              order: nil,
              filter: nil,
              procedure_id: procedure_id,
              gestionnaire: self
          )
        end
      end
    end
  end

  def build_default_preferences_smart_listing_page
    PreferenceSmartListingPage.create(page: 1, procedure: nil, gestionnaire: self, liste: 'a_traiter')
  end

  def notifications
    Notification.where(already_read: false, dossier_id: follows.pluck(:dossier_id)).order("updated_at DESC")
  end

  def notifications_for procedure
    procedure_ids = followed_dossiers.pluck(:procedure_id)

    if procedure_ids.include?(procedure.id)
      return followed_dossiers.where(procedure_id: procedure.id)
                 .inject(0) do |acc, dossier|
        acc += dossier.notifications.where(already_read: false).count
      end
    end
    0
  end

  def dossiers_with_notifications_count_for_procedure(procedure)
    followed_dossiers_id = followed_dossiers.where(procedure: procedure).pluck(:id)
    Notification.unread.where(dossier_id: followed_dossiers_id).select(:dossier_id).distinct(:dossier_id).count
  end

  def dossiers_with_notifications_count
    notifications.pluck(:dossier_id).uniq.count
  end

  def last_week_overview
    start_date = DateTime.now.beginning_of_week

    active_procedure_overviews = procedures
                            .where(published: true)
                            .all
                            .map { |procedure| procedure.procedure_overview(start_date, dossiers_with_notifications_count_for_procedure(procedure)) }
                            .select(&:had_some_activities?)

    if active_procedure_overviews.count == 0 && notifications.count == 0
      nil
    else
      {
        start_date: start_date,
        procedure_overviews: active_procedure_overviews,
        notifications: notifications
      }
    end
  end

  private

  def valid_couple_table_attr? table, column
    couples = [{
                   table: :dossier,
                   column: :dossier_id
               }, {
                   table: :procedure,
                   column: :libelle
               }, {
                   table: :etablissement,
                   column: :siret
               }, {
                   table: :entreprise,
                   column: :raison_sociale
               }, {
                   table: :dossier,
                   column: :state
               }]

    couples.include?({table: table, column: column})
  end
end
