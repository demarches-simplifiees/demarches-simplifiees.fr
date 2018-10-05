class ProcedurePresentation < ApplicationRecord
  EXTRA_SORT_COLUMNS = {
    'notifications' => Set['notifications'],
    'self' => Set['id', 'state']
  }

  belongs_to :assign_to

  delegate :procedure, to: :assign_to

  validate :check_allowed_displayed_fields
  validate :check_allowed_sort_column
  validate :check_allowed_filter_columns

  def check_allowed_displayed_fields
    displayed_fields.each do |field|
      table = field['table']
      column = field['column']
      if !dossier_field_service.valid_column?(procedure, table, column)
        errors.add(:filters, "#{table}.#{column} n’est pas une colonne permise")
      end
    end
  end

  def check_allowed_sort_column
    table = sort['table']
    column = sort['column']
    if !valid_sort_column?(procedure, table, column)
      errors.add(:sort, "#{table}.#{column} n’est pas une colonne permise")
    end
  end

  def check_allowed_filter_columns
    filters.each do |_, columns|
      columns.each do |column|
        table = column['table']
        column = column['column']
        if !dossier_field_service.valid_column?(procedure, table, column)
          errors.add(:filters, "#{table}.#{column} n’est pas une colonne permise")
        end
      end
    end
  end

  def fields
    dossier_field_service.fields(procedure)
  end

  def fields_for_select
    fields.map do |field|
      [field['label'], "#{field['table']}/#{field['column']}"]
    end
  end

  def sorted_ids(dossiers, gestionnaire)
    table = sort['table']
    column = sanitized_column(sort)
    order = sort['order']
    assert_valid_order(order)

    case table
    when 'notifications'
      dossiers_id_with_notification = gestionnaire.notifications_for_procedure(procedure)
      if order == 'desc'
        return dossiers_id_with_notification +
            (dossiers.order('dossiers.updated_at desc').ids - dossiers_id_with_notification)
      else
        return (dossiers.order('dossiers.updated_at asc').ids - dossiers_id_with_notification) +
            dossiers_id_with_notification
      end
    when 'self'
      return dossiers
          .order("#{column} #{order}")
          .pluck(:id)
    when 'type_de_champ', 'type_de_champ_private'
      return dossiers
          .includes(table == 'type_de_champ' ? :champs : :champs_private)
          .where("champs.type_de_champ_id = #{sort['column'].to_i}")
          .order("champs.value #{order}")
          .pluck(:id)
    else
      return dossiers
          .includes(table)
          .order("#{column} #{order}")
          .pluck(:id)
    end
  end

  def filtered_ids(dossiers, statut)
    filters[statut].map do |filter|
      table = filter['table']
      column = sanitized_column(filter)
      case table
      when 'self'
        dossiers.where("? ILIKE ?", filter['column'], "%#{filter['value']}%")

      when 'france_connect_information'
        dossiers
          .includes(user: :france_connect_information)
          .where("? ILIKE ?", "france_connect_informations.#{filter['column']}", "%#{filter['value']}%")

      when 'type_de_champ', 'type_de_champ_private'
        relation = table == 'type_de_champ' ? :champs : :champs_private
        dossiers
          .includes(relation)
          .where("champs.type_de_champ_id = ?", filter['column'].to_i)
          .where("champs.value ILIKE ?", "%#{filter['value']}%")
      when 'etablissement'
        if filter['column'] == 'entreprise_date_creation'
          date = filter['value'].to_date rescue nil
          dossiers
            .includes(table)
            .where("#{column} = ?", date)
        else
          dossiers
            .includes(table)
            .where("#{column} ILIKE ?", "%#{filter['value']}%")
        end
      when 'user'
        dossiers
          .includes(table)
          .where("#{column} ILIKE ?", "%#{filter['value']}%")
      end.pluck(:id)
    end.reduce(:&)
  end

  private

  def assert_valid_order(order)
    if !["asc", "desc"].include?(order)
      raise "Invalid order #{order}"
    end
  end

  def sanitized_column(field)
    table = field['table']
    table = ActiveRecord::Base.connection.quote_column_name((table == 'self' ? 'dossier' : table).pluralize)
    column = ActiveRecord::Base.connection.quote_column_name(field['column'])

    table + '.' + column
  end

  def dossier_field_service
    @dossier_field_service ||= DossierFieldService.new
  end

  def valid_sort_column?(procedure, table, column)
    dossier_field_service.valid_column?(procedure, table, column) || EXTRA_SORT_COLUMNS[table]&.include?(column)
  end
end
