# frozen_string_literal: true

class Column
  # include validations to enable procedure_presentation.validate_associate,
  # which enforces the deserialization of columns in the displayed_columns attribute
  # and raises an error if a column is not found
  include ActiveModel::Validations

  TYPE_DE_CHAMP_TABLE = 'type_de_champ'

  attr_reader :table, :column, :label, :type, :scope, :value_column, :filterable, :displayable

  def initialize(procedure_id:, table:, column:, label: nil, type: :text, value_column: :value, filterable: true, displayable: true, scope: '')
    @procedure_id = procedure_id
    @table = table
    @column = column
    @label = label || I18n.t(column, scope: [:activerecord, :attributes, :procedure_presentation, :fields, table])
    @type = type
    @scope = scope
    @value_column = value_column
    @filterable = filterable
    @displayable = displayable
  end

  # the id is a String to be used in forms
  def id = h_id.to_json

  # the h_id is a Hash and hold enough information to find the column
  # in the ColumnType class, aka be able to do the h_id -> column conversion
  def h_id = { procedure_id: @procedure_id, column_id: "#{table}/#{column}" }

  def ==(other) = h_id == other.h_id # using h_id instead of id to avoid inversion of keys

  def to_json
    {
      table:, column:, label:, type:, scope:, value_column:, filterable:, displayable:
    }
  end

  def notifications? = [table, column] == ['notifications', 'notifications']

  def dossier_state? = [table, column] == ['self', 'state']

  def enum? = @type == :enum

  def self.find(h_id)
    begin
      procedure = Procedure.with_discarded.find(h_id[:procedure_id])
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound.new("Column: unable to find procedure #{h_id[:procedure_id]} from h_id #{h_id}")
    end

    procedure.find_column(h_id: h_id)
  end

  def get_value(dossier_or_champ)
    raw_value = case table
    when 'self'
      dossier_or_champ.send(column)
    when 'etablissement'
      dossier_or_champ.etablissement.send(column)
    when 'individual'
      dossier_or_champ.individual.send(column)
    when 'groupe_instructeur'
      dossier_or_champ.groupe_instructeur.label
    when 'followers_instructeurs'
      dossier_or_champ.followers_instructeurs.map(&:email).join(' ')
    when 'type_de_champ'
      dossier_or_champ.send(value_column)
    end

    # TODO, extract columns by type + add method format_value
    if enum? && I18n.exists?(raw_value, scope: scope)
      raw_value = I18n.t(raw_value, scope: scope)
    end

    raw_value
  end
end
