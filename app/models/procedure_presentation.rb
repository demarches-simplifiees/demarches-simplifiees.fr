# frozen_string_literal: true

class ProcedurePresentation < ApplicationRecord
  TYPE_DE_CHAMP = 'type_de_champ'

  belongs_to :assign_to, optional: false
  has_many :exports, dependent: :destroy

  delegate :procedure, :instructeur, to: :assign_to

  attribute :displayed_columns, :column, array: true

  attribute :sorted_column, :sorted_column
  def sorted_column = super || procedure.default_sorted_column # Dummy override to set default value

  attribute :a_suivre_filters, :filtered_column, array: true
  attribute :suivis_filters, :filtered_column, array: true
  attribute :traites_filters, :filtered_column, array: true
  attribute :tous_filters, :filtered_column, array: true
  attribute :supprimes_filters, :filtered_column, array: true
  attribute :supprimes_recemment_filters, :filtered_column, array: true
  attribute :expirant_filters, :filtered_column, array: true
  attribute :archives_filters, :filtered_column, array: true

  before_create { self.displayed_columns = procedure.default_displayed_columns }

  validates_associated :displayed_columns, :sorted_column, :a_suivre_filters, :suivis_filters,
    :traites_filters, :tous_filters, :supprimes_filters, :expirant_filters, :archives_filters

  def filters_for(statut)
    send(filters_name_for(statut))
  end

  def filters_name_for(statut) = statut.tr('-', '_').then { "#{_1}_filters" }

  def displayed_fields_for_headers
    [
      procedure.dossier_id_column,
      *displayed_columns,
      procedure.dossier_state_column,
      *procedure.sva_svr_columns
    ]
  end

  def human_value_for_filter(filtered_column)
    if filtered_column.column.table == TYPE_DE_CHAMP
      find_type_de_champ(filtered_column.column.column).dynamic_type.filter_to_human(filtered_column.filter)
    elsif filtered_column.column.column == 'state'
      if filtered_column.filter == 'pending_correction'
        Dossier.human_attribute_name("pending_correction.for_instructeur")
      else
        Dossier.human_attribute_name("state.#{filtered_column.filter}")
      end
    elsif filtered_column.column.table == 'groupe_instructeur' && filtered_column.column.column == 'id'
      instructeur.groupe_instructeurs
        .find { _1.id == filtered_column.filter.to_i }&.label || filtered_column.filter
    else
      column = procedure.columns.find { _1.table == filtered_column.column.table && _1.column == filtered_column.column.column }

      if column.type == :date
        parsed_date = safe_parse_date(filtered_column.filter)

        return parsed_date.present? ? I18n.l(parsed_date) : nil
      end

      filtered_column.filter
    end
  end

  def safe_parse_date(string)
    Date.parse(string)
  rescue Date::Error
    nil
  end

  private

  def find_type_de_champ(column)
    TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(revision_types_de_champ: { revision_id: procedure.revisions })
      .order(created_at: :desc)
      .find_by(stable_id: column)
  end
end
