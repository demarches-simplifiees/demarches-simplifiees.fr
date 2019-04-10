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
      field_hash('Demandeur', 'user', 'email'),
      field_hash('Email instructeur', 'followers_gestionnaires', 'email')
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
    when 'self', 'user', 'individual', 'etablissement', 'followers_gestionnaires'
      return (table == 'self' ? dossiers : dossiers.includes(table))
          .order("#{self.class.sanitized_column(table, column)} #{order}")
          .pluck(:id)
    end
  end

  def filtered_ids(dossiers, statut)
    dossiers.each { |dossier| assert_matching_procedure(dossier) }
    filters[statut].group_by { |filter| filter.values_at('table', 'column') } .map do |(table, column), filters|
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
          .filter_ilike(relation, :value, values)
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
      when 'user', 'individual', 'followers_gestionnaires'
        dossiers
          .includes(table)
          .filter_ilike(table, column, values)
      end.pluck(:id)
    end.reduce(:&)
  end

  def eager_load_displayed_fields(dossiers)
    relations_to_include = displayed_fields
      .pluck('table')
      .reject { |table| table == 'self' }
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

    dossiers.includes(relations_to_include)
  end

  private

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
    filters.each do |_, columns|
      columns.each do |column|
        check_allowed_field(:filters, column)
      end
    end
  end

  def check_allowed_field(kind, field, extra_columns = {})
    table, column = field.values_at('table', 'column')
    if !valid_column?(table, column, extra_columns)
      errors.add(kind, "#{table}.#{column} n’est pas une colonne permise")
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
    when 'followers_gestionnaires'
      dossier.send(table)&.map { |g| g.send(column) }&.join(', ')
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

  def valid_column?(table, column, extra_columns = {})
    valid_columns_for_table(table).include?(column) ||
      extra_columns[table]&.include?(column)
  end

  def valid_columns_for_table(table)
    @column_whitelist ||= fields
      .group_by { |field| field['table'] }
      .map { |table, fields| [table, Set.new(fields.pluck('column'))] }
      .to_h

    @column_whitelist[table] || []
  end

  def self.sanitized_column(association, column)
    table = if association == 'self'
      Dossier.table_name
    else
      Dossier.reflect_on_association(association).klass.table_name
    end

    [table, column]
      .map { |name| ActiveRecord::Base.connection.quote_column_name(name) }
      .join('.')
  end

  def dossier_field_service
    @dossier_field_service ||= DossierFieldService.new
  end
end
