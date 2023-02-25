# == Schema Information
#
# Table name: procedure_presentations
#
#  id               :integer          not null, primary key
#  displayed_fields :jsonb            not null
#  filters          :jsonb            not null
#  sort             :jsonb            not null
#  created_at       :datetime
#  updated_at       :datetime
#  assign_to_id     :integer
#
class ProcedurePresentation < ApplicationRecord
  EXTRA_SORT_COLUMNS = {
    'notifications' => ['notifications'],
    'self' => ['id', 'state']
  }

  TABLE = 'table'
  COLUMN = 'column'
  ORDER = 'order'

  SLASH = '/'
  TYPE_DE_CHAMP = 'type_de_champ'
  TYPE_DE_CHAMP_PRIVATE = 'type_de_champ_private'

  FILTERS_VALUE_MAX_LENGTH = 100

  belongs_to :assign_to, optional: false
  has_many :exports, dependent: :destroy

  delegate :procedure, :instructeur, to: :assign_to

  validate :check_allowed_displayed_fields
  validate :check_allowed_sort_column
  validate :check_allowed_sort_order
  validate :check_allowed_filter_columns
  validate :check_filters_max_length

  def self_fields
    [
      field_hash('self', 'created_at', type: :date),
      field_hash('self', 'updated_at', type: :date),
      field_hash('self', 'depose_at', type: :date),
      field_hash('self', 'en_construction_at', type: :date),
      field_hash('self', 'en_instruction_at', type: :date),
      field_hash('self', 'processed_at', type: :date),
      field_hash('self', 'updated_since', type: :date, virtual: true),
      field_hash('self', 'depose_since', type: :date, virtual: true),
      field_hash('self', 'en_construction_since', type: :date, virtual: true),
      field_hash('self', 'en_instruction_since', type: :date, virtual: true),
      field_hash('self', 'processed_since', type: :date, virtual: true),
      field_hash('self', 'state', type: :enum, scope: 'instructeurs.dossiers.filterable_state', virtual: true)
    ]
  end

  def fields
    fields = self_fields

    fields.push(
      field_hash('user', 'email', type: :text),
      field_hash('followers_instructeurs', 'email', type: :text),
      field_hash('groupe_instructeur', 'label', type: :text)
    )

    if procedure.for_individual
      fields.push(
        field_hash("individual", "prenom", type: :text),
        field_hash("individual", "nom", type: :text),
        field_hash("individual", "gender", type: :text)
      )
    end

    if !procedure.for_individual
      fields.push(
        field_hash('etablissement', 'entreprise_siren', type: :text),
        field_hash('etablissement', 'entreprise_forme_juridique', type: :text),
        field_hash('etablissement', 'entreprise_nom_commercial', type: :text),
        field_hash('etablissement', 'entreprise_raison_sociale', type: :text),
        field_hash('etablissement', 'entreprise_siret_siege_social', type: :text),
        field_hash('etablissement', 'entreprise_date_creation', type: :date)
      )

      fields.push(
        field_hash('etablissement', 'siret', type: :text),
        field_hash('etablissement', 'libelle_naf', type: :text),
        field_hash('etablissement', 'code_postal', type: :text)
      )
    end

    fields.concat procedure.types_de_champ_for_procedure_presentation
      .pluck(:libelle, :private, :stable_id)
      .map { |(libelle, is_private, stable_id)| field_hash(is_private ? TYPE_DE_CHAMP_PRIVATE : TYPE_DE_CHAMP, stable_id.to_s, label: libelle, type: :text) }

    fields
  end

  def displayable_fields_for_select
    [
      fields.reject { |field| field['virtual'] }
        .map { |field| [field['label'], field_id(field)] },
      displayed_fields.map { |field| field_id(field) }
    ]
  end

  def filterable_fields_options
    fields.map do |field|
      [field['label'], field_id(field)]
    end
  end

  def displayed_fields_for_headers
    [
      field_hash('self', 'id', classname: 'number-col'),
      *displayed_fields,
      field_hash('self', 'state', classname: 'state-col')
    ]
  end

  def sorted_ids(dossiers, count)
    table, column, order = sort.values_at(TABLE, COLUMN, 'order')

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
    when TYPE_DE_CHAMP_PRIVATE
      ids = dossiers
        .with_type_de_champ_private(column)
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
      case table
      when 'self'
        field = self_fields.find { |h| h['column'] == column }
        if field['type'] == :date
          dates = values
            .filter_map { |v| Time.zone.parse(v).beginning_of_day rescue nil }

          dossiers.filter_by_datetimes(column, dates)
        else
          dossiers.where("dossiers.#{column} = ?", values)
        end
      when TYPE_DE_CHAMP
        dossiers.with_type_de_champ(column)
          .filter_ilike(:champs, :value, values)
      when TYPE_DE_CHAMP_PRIVATE
        dossiers.with_type_de_champ_private(column)
          .filter_ilike(:champs_private, :value, values)
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
          .filter_ilike('instructeurs_users', :email, values)
      when 'user', 'individual'
        dossiers
          .includes(table)
          .filter_ilike(table, column, values)
      when 'groupe_instructeur'
        dossiers
          .joins(:groupe_instructeur)
          .filter_ilike(table, column, values)
      end.pluck(:id)
    end.reduce(:&)
  end

  def filtered_sorted_ids(dossiers, statut, count: nil)
    dossiers_by_statut = dossiers.by_statut(instructeur, statut)
    dossiers_sorted_ids = self.sorted_ids(dossiers_by_statut, count || dossiers_by_statut.size)

    if filters[statut].present?
      dossiers_sorted_ids.intersection(filtered_ids(dossiers_by_statut, statut))
    else
      dossiers_sorted_ids
    end
  end

  def human_value_for_filter(filter)
    case filter[TABLE]
    when TYPE_DE_CHAMP, TYPE_DE_CHAMP_PRIVATE
      find_type_de_champ(filter[COLUMN]).dynamic_type.filter_to_human(filter['value'])
    else
      filter['value']
    end
  end

  def add_filter(statut, field, value)
    if value.present?
      table, column = field.split(SLASH)
      label = find_field(table, column)['label']

      case table
      when TYPE_DE_CHAMP, TYPE_DE_CHAMP_PRIVATE
        value = find_type_de_champ(column).dynamic_type.human_to_filter(value)
      end

      updated_filters = filters.dup
      updated_filters[statut] << {
        'label' => label,
        TABLE => table,
        COLUMN => column,
        'value' => value
      }

      update!(filters: updated_filters)
    end
  end

  def remove_filter(statut, field, value)
    table, column = field.split(SLASH)

    updated_filters = filters.dup
    updated_filters[statut] = filters[statut].reject do |filter|
      filter.values_at(TABLE, COLUMN, 'value') == [table, column, value]
    end

    update!(filters: updated_filters)
  end

  def update_displayed_fields(values)
    if values.nil?
      values = []
    end

    fields = values.map { |value| find_field(*value.split(SLASH)) }

    update!(displayed_fields: fields)

    if !values.include?(field_id(sort))
      update!(sort: Procedure.default_sort)
    end
  end

  def update_sort(table, column, order)
    update!(sort: {
      TABLE => table,
      COLUMN => column,
      ORDER => opposite_order_for(table, column)
    })
  end

  def opposite_order_for(table, column)
    if sort.values_at(TABLE, COLUMN) == [table, column]
      sort['order'] == 'asc' ? 'desc' : 'asc'
    else
      'asc'
    end
  end

  def snapshot
    slice(:filters, :sort, :displayed_fields)
  end

  def field_type(field_id)
    find_field(*field_id.split(SLASH))['type']
  end

  def field_enum(field_id)
    find_field(*field_id.split(SLASH))['scope']
  end

  private

  def field_id(field)
    field.values_at(TABLE, COLUMN).join(SLASH)
  end

  def find_field(table, column)
    fields.find { |field| field.values_at(TABLE, COLUMN) == [table, column] }
  end

  def find_type_de_champ(column)
    TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(revision_types_de_champ: { revision_id: procedure.revisions })
      .order(:created_at)
      .find_by(stable_id: column)
  end

  def check_allowed_displayed_fields
    displayed_fields.each do |field|
      check_allowed_field(:displayed_fields, field)
    end
  end

  def check_allowed_sort_column
    check_allowed_field(:sort, sort, EXTRA_SORT_COLUMNS)
  end

  def check_allowed_sort_order
    order = sort['order']
    if !["asc", "desc"].include?(order)
      errors.add(:sort, "#{order} n’est pas une ordre permis")
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
    individual_filters = filters.values.flatten.filter { |f| f.is_a?(Hash) }
    individual_filters.each do |filter|
      if filter['value']&.length.to_i > FILTERS_VALUE_MAX_LENGTH
        errors.add(:filters, :too_long)
      end
    end
  end

  def field_hash(table, column, label: nil, classname: '', virtual: false, type: :text, scope: '')
    {
      'label' => label || I18n.t(column, scope: [:activerecord, :attributes, :procedure_presentation, :fields, table]),
      TABLE => table,
      COLUMN => column,
      'classname' => classname,
      'virtual' => virtual,
      'type' => type,
      'scope' => scope
    }
  end

  def valid_column?(table, column, extra_columns = {})
    valid_columns_for_table(table).include?(column) ||
      extra_columns[table]&.include?(column)
  end

  def valid_columns_for_table(table)
    @column_whitelist ||= fields
      .group_by { |field| field[TABLE] }
      .transform_values { |fields| Set.new(fields.pluck(COLUMN)) }

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
  end
end
