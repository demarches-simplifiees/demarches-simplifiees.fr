# frozen_string_literal: true

class ProcedurePresentation < ApplicationRecord
  TABLE = 'table'
  COLUMN = 'column'
  ORDER = 'order'

  SLASH = '/'
  TYPE_DE_CHAMP = 'type_de_champ'

  FILTERS_VALUE_MAX_LENGTH = 100
  # https://www.postgresql.org/docs/current/datatype-numeric.html
  PG_INTEGER_MAX_VALUE = 2147483647

  belongs_to :assign_to, optional: false
  has_many :exports, dependent: :destroy

  delegate :procedure, :instructeur, to: :assign_to

  validate :check_allowed_displayed_fields
  validate :check_allowed_filter_columns
  validate :check_filters_max_length
  validate :check_filters_max_integer

  attribute :sorted_column, :sorted_column
  def sorted_column = super || procedure.default_sorted_column # Dummy override to set default value

  attribute :a_suivre_filters, :jsonb, array: true
  attribute :suivis_filters, :jsonb, array: true
  attribute :traites_filters, :jsonb, array: true
  attribute :tous_filters, :jsonb, array: true
  attribute :supprimes_filters, :jsonb, array: true
  attribute :supprimes_recemment_filters, :jsonb, array: true
  attribute :expirant_filters, :jsonb, array: true
  attribute :archives_filters, :jsonb, array: true

  def filters_for(statut)
    send(filters_name_for(statut))
  end

  def filters_name_for(statut) = statut.tr('-', '_').then { "#{_1}_filters" }

  def displayed_fields_for_headers
    [
      Column.new(procedure_id: procedure.id, table: 'self', column: 'id', classname: 'number-col'),
      *displayed_fields.map { Column.new(**_1.deep_symbolize_keys.merge(procedure_id: procedure.id)) },
      Column.new(procedure_id: procedure.id, table: 'self', column: 'state', classname: 'state-col'),
      *procedure.sva_svr_columns
    ]
  end

  def filtered_sorted_ids(dossiers, statut, count: nil)
    dossiers_by_statut = dossiers.by_statut(statut, instructeur)
    dossiers_sorted_ids = self.sorted_ids(dossiers_by_statut, count || dossiers_by_statut.size)

    if filters[statut].present?
      dossiers_sorted_ids.intersection(filtered_ids(dossiers_by_statut, statut))
    else
      dossiers_sorted_ids
    end
  end

  def human_value_for_filter(filter)
    if filter[TABLE] == TYPE_DE_CHAMP
      find_type_de_champ(filter[COLUMN]).dynamic_type.filter_to_human(filter['value'])
    elsif filter['column'] == 'state'
      if filter['value'] == 'pending_correction'
        Dossier.human_attribute_name("pending_correction.for_instructeur")
      else
        Dossier.human_attribute_name("state.#{filter['value']}")
      end
    elsif filter['table'] == 'groupe_instructeur' && filter['column'] == 'id'
      instructeur.groupe_instructeurs
        .find { _1.id == filter['value'].to_i }&.label || filter['value']
    else
      column = procedure.columns.find { _1.table == filter[TABLE] && _1.column == filter[COLUMN] }

      if column.type == :date
        parsed_date = safe_parse_date(filter['value'])

        return parsed_date.present? ? I18n.l(parsed_date) : nil
      end

      filter['value']
    end
  end

  def safe_parse_date(string)
    Date.parse(string)
  rescue Date::Error
    nil
  end

  def add_filter(statut, column_id, value)
    h_id = JSON.parse(column_id, symbolize_names: true)

    if value.present?
      column = procedure.find_column(h_id:)

      case column.table
      when TYPE_DE_CHAMP
        value = find_type_de_champ(column.column).dynamic_type.human_to_filter(value)
      end

      updated_filters = filters.dup
      updated_filters[statut] << {
        'label' => column.label,
        TABLE => column.table,
        COLUMN => column.column,
        'value_column' => column.value_column,
        'value' => value
      }

      filters_for(statut) << { id: h_id, filter: value }
      update(filters: updated_filters)
    end
  end

  def remove_filter(statut, column_id, value)
    h_id = JSON.parse(column_id, symbolize_names: true)
    column = procedure.find_column(h_id:)
    updated_filters = filters.dup

    updated_filters[statut] = filters[statut].reject do |filter|
      filter.values_at(TABLE, COLUMN, 'value') == [column.table, column.column, value]
    end

    collection = filters_for(statut)
    collection.delete(collection.find { sym_h = _1.deep_symbolize_keys; sym_h[:id] == h_id && sym_h[:filter] == value })

    update!(filters: updated_filters)
  end

  def update_displayed_fields(column_ids)
    h_ids = Array.wrap(column_ids).map { |id| JSON.parse(id, symbolize_names: true) }
    columns = h_ids.map { |h_id| procedure.find_column(h_id:) }

    update!(
      displayed_fields: columns,
      displayed_columns: columns.map(&:h_id)
    )

    if !sorted_column.column.in?(columns)
      update(sorted_column: nil)
    end
  end

  def snapshot
    slice(:filters, :sort, :displayed_fields)
  end

  private

  def sorted_ids(dossiers, count)
    table = sorted_column.column.table
    column = sorted_column.column.column
    order = sorted_column.order

    case table
    when 'notifications'
      dossiers_id_with_notification = dossiers.merge(instructeur.followed_dossiers).with_notifications.ids
      if order == 'desc'
        dossiers_id_with_notification +
            (dossiers.order('dossiers.updated_at desc').ids - dossiers_id_with_notification)
      else
        (dossiers.order('dossiers.updated_at asc').ids - dossiers_id_with_notification) +
            dossiers_id_with_notification
      end
    when TYPE_DE_CHAMP
      ids = dossiers
        .with_type_de_champ(column)
        .order("champs.value #{order}")
        .pluck(:id)
      if ids.size != count
        rest = dossiers.where.not(id: ids).order(id: order).pluck(:id)
        order == 'asc' ? ids + rest : rest + ids
      else
        ids
      end
    when 'followers_instructeurs'
      assert_supported_column(table, column)
      # LEFT OUTER JOIN allows to keep dossiers without assigned instructeurs yet
      dossiers
        .includes(:followers_instructeurs)
        .joins('LEFT OUTER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
        .order("instructeurs_users.email #{order}")
        .pluck(:id)
        .uniq
    when 'avis'
      dossiers.includes(table)
        .order("#{self.class.sanitized_column(table, column)} #{order}")
        .pluck(:id)
        .uniq
    when 'self', 'user', 'individual', 'etablissement', 'groupe_instructeur'
      (table == 'self' ? dossiers : dossiers.includes(table))
        .order("#{self.class.sanitized_column(table, column)} #{order}")
        .pluck(:id)
    end
  end

  def filtered_ids(dossiers, statut)
    filters.fetch(statut)
      .group_by { |filter| filter.values_at(TABLE, COLUMN) }
      .map do |(table, column), filters|
      values = filters.pluck('value')
      value_column = filters.pluck('value_column').compact.first || :value
      dossier_column = procedure.find_column(h_id: { procedure_id: procedure.id, column_id: "#{table}/#{column}" }) # hack to find json path columns
      if dossier_column.is_a?(Columns::JSONPathColumn)
        dossier_column.filtered_ids(dossiers, values)
      else
        case table
        when 'self'
          if dossier_column.type == :date
            dates = values
              .filter_map { |v| Time.zone.parse(v).beginning_of_day rescue nil }

            dossiers.filter_by_datetimes(column, dates)
          elsif dossier_column.column == "state" && values.include?("pending_correction")
            dossiers.joins(:corrections).where(corrections: DossierCorrection.pending)
          elsif dossier_column.column == "state" && values.include?("en_construction")
            dossiers.where("dossiers.#{column} IN (?)", values).includes(:corrections).where.not(corrections: DossierCorrection.pending)
          else
            dossiers.where("dossiers.#{column} IN (?)", values)
          end
        when TYPE_DE_CHAMP
          if dossier_column.type == :enum
            dossiers.with_type_de_champ(column)
              .filter_enum(:champs, value_column, values)
          else
            dossiers.with_type_de_champ(column)
              .filter_ilike(:champs, value_column, values)
          end
        when 'etablissement'
          if column == 'entreprise_date_creation'
            dates = values
              .filter_map { |v| v.to_date rescue nil }

            dossiers
              .includes(table)
              .where(table.pluralize => { column => dates })
          else
            dossiers
              .includes(table)
              .filter_ilike(table, column, values)
          end
        when 'followers_instructeurs'
          assert_supported_column(table, column)
          dossiers
            .includes(:followers_instructeurs)
            .joins('INNER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
            .filter_ilike('instructeurs_users', :email, values) # ilike OK, user may want to search by *@domain
        when 'user', 'individual' # user_columns: [email], individual_columns: ['nom', 'prenom', 'gender']
          dossiers
            .includes(table)
            .filter_ilike(table, column, values) # ilike or where column == 'value' are both valid, we opted for ilike
        when 'groupe_instructeur'
          assert_supported_column(table, column)

          dossiers
            .joins(:groupe_instructeur)
            .where(groupe_instructeur_id: values)
        end.pluck(:id)
      end
    end.reduce(:&)
  end

  def find_type_de_champ(column)
    TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(revision_types_de_champ: { revision_id: procedure.revisions })
      .order(created_at: :desc)
      .find_by(stable_id: column)
  end

  def check_allowed_displayed_fields
    displayed_fields.each do |field|
      check_allowed_field(:displayed_fields, field)
    end
  end

  def check_allowed_filter_columns
    filters.each do |key, columns|
      return true if key == 'migrated'
      columns.each do |column|
        check_allowed_field(:filters, column)
      end
    end
  end

  def check_allowed_field(kind, field, extra_columns = {})
    table, column = field.values_at(TABLE, COLUMN)
    if !valid_column?(table, column, extra_columns)
      errors.add(kind, "#{table}.#{column} n’est pas une colonne permise")
    end
  end

  def check_filters_max_length
    filters.values.flatten.each do |filter|
      next if !filter.is_a?(Hash)
      next if filter['value']&.length.to_i <= FILTERS_VALUE_MAX_LENGTH

      errors.add(:base, "Le filtre #{filter['label']} est trop long (maximum: #{FILTERS_VALUE_MAX_LENGTH} caractères)")
    end
  end

  def check_filters_max_integer
    filters.values.flatten.each do |filter|
      next if !filter.is_a?(Hash)
      next if filter['column'] != 'id'
      next if filter['value']&.to_i&. < PG_INTEGER_MAX_VALUE

      errors.add(:base, "Le filtre #{filter['label']} n'est pas un numéro de dossier possible")
    end
  end

  def valid_column?(table, column, extra_columns = {})
    valid_columns_for_table(table).include?(column) ||
      extra_columns[table]&.include?(column)
  end

  def valid_columns_for_table(table)
    @column_whitelist ||= procedure.columns
      .group_by(&:table)
      .transform_values { |columns| Set.new(columns.map(&:column)) }

    @column_whitelist[table] || []
  end

  def self.sanitized_column(association, column)
    table = if association == 'self'
      Dossier.table_name
    elsif (association_reflection = Dossier.reflect_on_association(association))
      association_reflection.klass.table_name
    else
      # Allow filtering on a joined table alias (which doesn’t exist
      # in the ActiveRecord domain).
      association
    end

    [table, column]
      .map { |name| ActiveRecord::Base.connection.quote_column_name(name) }
      .join('.')
  end

  def assert_supported_column(table, column)
    if table == 'followers_instructeurs' && column != 'email'
      raise ArgumentError, 'Table `followers_instructeurs` only supports the `email` column.'
    end
    if table == 'groupe_instructeur' && (column != 'label' && column != 'id')
      raise ArgumentError, 'Table `groupe_instructeur` only supports the `label` or `id` column.'
    end
  end
end
