# frozen_string_literal: true

class ProcedurePresentation < ApplicationRecord
  ALL_FILTERS = [
    :a_suivre_filters,
    :suivis_filters,
    :traites_filters,
    :tous_filters,
    :supprimes_filters,
    :supprimes_recemment_filters,
    :expirant_filters,
    :archives_filters,
  ]

  self.ignored_columns += ["displayed_fields", "filters", "sort"]

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
  before_create :set_default_filters

  validates_associated :displayed_columns, :sorted_column, :a_suivre_filters, :suivis_filters,
    :traites_filters, :tous_filters, :supprimes_filters, :expirant_filters, :archives_filters

  def filters_for(statut)
    send(filters_name_for(statut))
  end

  def destroy_filters_for!(statut)
    update!(filters_name_for(statut) => [])
  end

  def add_filter_for_statut!(statut, filter)
    filters_attr = filters_name_for(statut)
    current_filters = send(filters_attr) || []
    update!(filters_attr => current_filters + [filter])
  end

  def update_filter_for_statut!(statut, filter_key, filter)
    filters_attr = filters_name_for(statut)
    current_filters = send(filters_attr) || []
    update!(filters_attr => current_filters.map { |f| f.id == filter_key ? filter : f })
  end

  def remove_filter_for_statut!(statut, filter_to_remove)
    filters_attr = filters_name_for(statut)

    update!(filters_attr => filters_for(statut).reject do |filter|
      filter_to_remove == filter
    end)
  end

  def filters_name_for(statut) = statut.tr('-', '_').then { "#{_1}_filters" }

  def displayed_fields_for_headers
    columns = [
      procedure.dossier_id_column,
      *displayed_columns,
      procedure.dossier_state_column,
    ]
    columns.concat(procedure.sva_svr_columns.filter(&:displayable)) if procedure.sva_svr_enabled?
    columns
  end

  def set_default_filters
    default_filters_for_all_statuts = [
      FilteredColumn.new(column: procedure.dossier_state_column, filter: { operator: 'match', value: [] }),
      FilteredColumn.new(column: procedure.dossier_id_column, filter: { operator: 'match', value: [] }),
      FilteredColumn.new(column: procedure.dossier_notifications_column, filter: { operator: 'match', value: [] })
    ]

    ALL_FILTERS.each do |filters_by_status|
      send("#{filters_by_status}=", default_filters_for_all_statuts) if send(filters_by_status).blank?
    end
  end
end
