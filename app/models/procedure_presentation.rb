# frozen_string_literal: true

class ProcedurePresentation < ApplicationRecord
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

  validates_associated :displayed_columns, :sorted_column, :a_suivre_filters, :suivis_filters,
    :traites_filters, :tous_filters, :supprimes_filters, :expirant_filters, :archives_filters

  def filters_for(statut)
    send(filters_name_for(statut))
  end

  def destroy_filters_for!(statut)
    update!(filters_name_for(statut) => [])
  end

  def filters_name_for(statut) = statut.tr('-', '_').then { "#{_1}_filters" }

  def displayed_fields_for_headers
    columns = [
      procedure.dossier_id_column,
      *displayed_columns,
      procedure.dossier_state_column
    ]
    columns.concat(procedure.sva_svr_columns.filter(&:displayable)) if procedure.sva_svr_enabled?
    columns
  end
end
