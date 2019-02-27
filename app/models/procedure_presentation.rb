class ProcedurePresentation < ApplicationRecord
  EXTRA_SORT_COLUMNS = {
    'notifications' => ['notifications'],
    'self' => ['id', 'state']
  }

  belongs_to :assign_to

  delegate :procedure, to: :assign_to

  validate :check_allowed_displayed_fields
  validate :check_allowed_sort_column
  validate :check_allowed_sort_order
  validate :check_allowed_filter_columns

  def fields
    fields = [
      field_hash('Créé le', 'self', 'created_at'),
      field_hash('En construction le', 'self', 'en_construction_at'),
      field_hash('Mis à jour le', 'self', 'updated_at'),
      field_hash('Demandeur', 'user', 'email')
    ]

    if procedure.for_individual
      fields.push(
        field_hash("Prénom", "individual", "prenom"),
        field_hash("Nom", "individual", "nom"),
        field_hash("Civilité", "individual", "gender")
      )
    end

    if !procedure.for_individual || (procedure.for_individual && procedure.individual_with_siret)
      fields.push(
        field_hash('SIREN', 'etablissement', 'entreprise_siren'),
        field_hash('Forme juridique', 'etablissement', 'entreprise_forme_juridique'),
        field_hash('Nom commercial', 'etablissement', 'entreprise_nom_commercial'),
        field_hash('Raison sociale', 'etablissement', 'entreprise_raison_sociale'),
        field_hash('SIRET siège social', 'etablissement', 'entreprise_siret_siege_social'),
        field_hash('Date de création', 'etablissement', 'entreprise_date_creation')
      )

      fields.push(
        field_hash('SIRET', 'etablissement', 'siret'),
        field_hash('Libellé NAF', 'etablissement', 'libelle_naf'),
        field_hash('Code postal', 'etablissement', 'code_postal')
      )
    end

    explanatory_types_de_champ = [:header_section, :explication].map { |k| TypeDeChamp.type_champs.fetch(k) }

    fields.concat procedure.types_de_champ
      .where.not(type_champ: explanatory_types_de_champ)
      .order(:id)
      .map { |type_de_champ| field_hash(type_de_champ.libelle, 'type_de_champ', type_de_champ.id.to_s) }

    fields.concat procedure.types_de_champ_private
      .where.not(type_champ: explanatory_types_de_champ)
      .order(:id)
      .map { |type_de_champ| field_hash(type_de_champ.libelle, 'type_de_champ_private', type_de_champ.id.to_s) }

    fields
  end

  def fields_for_select
    fields.map do |field|
      [field['label'], "#{field['table']}/#{field['column']}"]
    end
  end

  def displayed_field_values(dossier)
    assert_matching_procedure(dossier)
    displayed_fields.map { |field| get_value(dossier, field['table'], field['column']) }
  end

  def sorted_ids(dossiers, gestionnaire)
    dossiers.each { |dossier| assert_matching_procedure(dossier) }
    table, column, order = sort.values_at('table', 'column', 'order')

    case table
    when 'notifications'
      dossiers_id_with_notification = gestionnaire.dossiers_id_with_notifications(dossiers)
      if order == 'desc'
        return dossiers_id_with_notification +
            (dossiers.order('dossiers.updated_at desc').ids - dossiers_id_with_notification)
      else
        return (dossiers.order('dossiers.updated_at asc').ids - dossiers_id_with_notification) +
            dossiers_id_with_notification
      end
    when 'type_de_champ', 'type_de_champ_private'
      return dossiers
          .includes(table == 'type_de_champ' ? :champs : :champs_private)
          .where("champs.type_de_champ_id = #{column.to_i}")
          .order("champs.value #{order}")
          .pluck(:id)
    when 'self', 'user', 'individual', 'etablissement'
      return (table == 'self' ? dossiers : dossiers.includes(table))
          .order("#{self.class.sanitized_column(table, column)} #{order}")
          .pluck(:id)
    end
  end

  def filtered_ids(dossiers, statut)
    dossiers.each { |dossier| assert_matching_procedure(dossier) }
    filters[statut].group_by { |filter| filter.slice('table', 'column') } .map do |field, filters|
      table, column = field.values_at('table', 'column')
      values = filters.pluck('value')
      case table
      when 'self'
        dates = values
          .map { |v| Time.zone.parse(v).beginning_of_day rescue nil }
          .compact
        dossiers.filter_by_datetimes(column, dates)
      when 'type_de_champ', 'type_de_champ_private'
        relation = table == 'type_de_champ' ? :champs : :champs_private
        dossiers
          .includes(relation)
          .where("champs.type_de_champ_id = ?", column.to_i)
          .filter_ilike(:champ, :value, values)
      when 'etablissement'
        if column == 'entreprise_date_creation'
          dates = values
            .map { |v| v.to_date rescue nil }
            .compact
          dossiers
            .includes(table)
            .where(table.pluralize => { column => dates })
        else
          dossiers
            .includes(table)
            .filter_ilike(table, column, values)
        end
      when 'user', 'individual'
        dossiers
          .includes(table)
          .filter_ilike(table, column, values)
      end.pluck(:id)
    end.reduce(:&)
  end

  def eager_load_displayed_fields(dossiers)
    fields_to_eager_load = displayed_fields.reject { |field| field['table'] == 'self' }

    relations_to_include = fields_to_eager_load
      .pluck('table')
      .map do |table|
        case table
        when 'type_de_champ'
          :champs
        when 'type_de_champ_private'
          :champs_private
        else
          table
        end
      end
      .uniq

    champ_fields = fields_to_eager_load.select do |field|
      ['type_de_champ', 'type_de_champ_private'].include?(field['table'])
    end

    if champ_fields.present?
      dossiers
        .includes(relations_to_include)
        .where(champs: { type_de_champ_id: champ_fields.pluck('column') })
    else
      dossiers.includes(relations_to_include)
    end
  end

  private

  def check_allowed_displayed_fields
    displayed_fields.each do |field|
      table = field['table']
      column = field['column']
      if !valid_column?(table, column)
        errors.add(:filters, "#{table}.#{column} n’est pas une colonne permise")
      end
    end
  end

  def check_allowed_sort_column
    table = sort['table']
    column = sort['column']
    if !valid_sort_column?(table, column)
      errors.add(:sort, "#{table}.#{column} n’est pas une colonne permise")
    end
  end

  def check_allowed_sort_order
    order = sort['order']
    if !["asc", "desc"].include?(order)
      errors.add(:sort, "#{order} n’est pas une ordre permis")
    end
  end

  def check_allowed_filter_columns
    filters.each do |_, columns|
      columns.each do |column|
        table = column['table']
        column = column['column']
        if !valid_column?(table, column)
          errors.add(:filters, "#{table}.#{column} n’est pas une colonne permise")
        end
      end
    end
  end

  def assert_matching_procedure(dossier)
    if dossier.procedure != procedure
      raise "Procedure mismatch (expected #{procedure.id}, got #{dossier.procedure.id})"
    end
  end

  def get_value(dossier, table, column)
    case table
    when 'self'
      dossier.send(column)&.strftime('%d/%m/%Y')
    when 'user', 'individual', 'etablissement'
      dossier.send(table)&.send(column)
    when 'type_de_champ'
      dossier.champs.find { |c| c.type_de_champ_id == column.to_i }.value
    when 'type_de_champ_private'
      dossier.champs_private.find { |c| c.type_de_champ_id == column.to_i }.value
    end
  end

  def field_hash(label, table, column)
    {
      'label' => label,
      'table' => table,
      'column' => column
    }
  end

  def valid_column?(table, column)
    valid_columns_for_table(table).include?(column)
  end

  def valid_columns_for_table(table)
    @column_whitelist ||= fields
      .group_by { |field| field['table'] }
      .map { |table, fields| [table, Set.new(fields.pluck('column'))] }
      .to_h

    @column_whitelist[table] || []
  end

  def self.sanitized_column(table, column)
    [(table == 'self' ? 'dossier' : table.to_s).pluralize, column]
      .map { |name| ActiveRecord::Base.connection.quote_column_name(name) }
      .join('.')
  end

  def dossier_field_service
    @dossier_field_service ||= DossierFieldService.new
  end

  def valid_sort_column?(table, column)
    valid_column?(table, column) || EXTRA_SORT_COLUMNS[table]&.include?(column)
  end
end
