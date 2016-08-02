class Gestionnaire < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_and_belongs_to_many :administrateurs

  has_many :assign_to, dependent: :destroy
  has_many :procedures, through: :assign_to
  has_many :dossiers, through: :procedures
  has_many :follows
  has_many :preference_list_dossiers

  after_create :build_default_preferences_list_dossier

  def dossiers_filter
    dossiers.where(procedure_id: procedure_filter_list)
  end

  def dossiers_follow
    dossiers.joins(:follows).where("follows.gestionnaire_id = #{id}")
  end

  def procedure_filter_list
    procedure_filter.empty? ? procedures.pluck(:id) : procedure_filter
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

  def build_default_preferences_list_dossier

    PreferenceListDossier.available_columns.each do |table|
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
              gestionnaire: self
          )
        end
      end
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
