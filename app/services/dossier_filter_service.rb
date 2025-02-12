# frozen_string_literal: true

class DossierFilterService
  TYPE_DE_CHAMP = 'type_de_champ'

  def self.filtered_sorted_ids(dossiers, statut, filtered_columns, sorted_column, instructeur, count: nil, include_archived: false)
    dossiers_by_statut = dossiers.by_statut(statut, instructeur:, include_archived:)
    dossiers_sorted_ids = self.sorted_ids(dossiers_by_statut, sorted_column, instructeur, count || dossiers_by_statut.size)

    if filtered_columns.present?
      dossiers_sorted_ids.intersection(filtered_ids(dossiers_by_statut, filtered_columns))
    else
      dossiers_sorted_ids
    end
  end

  private

  def self.sorted_ids(dossiers, sorted_column, instructeur, count)
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
      stable_id = sorted_column.column.stable_id
      ids = dossiers
        .with_type_de_champ(stable_id)
        .order("champs.value #{order}")
        .pluck(:id)
      if ids.size != count
        rest = dossiers.where.not(id: ids).order(id: order).pluck(:id)
        order == 'asc' ? ids + rest : rest + ids
      else
        ids
      end
    when 'followers_instructeurs'
      # LEFT OUTER JOIN allows to keep dossiers without assigned instructeurs yet
      dossiers
        .includes(:followers_instructeurs)
        .joins('LEFT OUTER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
        .order("instructeurs_users.email #{order}")
        .pluck(:id)
        .uniq
    when 'avis'
      dossiers.includes(table)
        .order("#{sanitized_column(table, column)} #{order}")
        .pluck(:id)
        .uniq
    when 'dossier_labels'
      dossiers.includes(:labels)
        .order("labels.name #{order}")
        .pluck(:id)
        .uniq
    when 'self', 'user', 'individual', 'etablissement', 'groupe_instructeur'
      (table == 'self' ? dossiers : dossiers.includes(table))
        .order("#{sanitized_column(table, column)} #{order}")
        .pluck(:id)
    end
  end

  def self.filtered_ids(dossiers, filtered_columns)
    filtered_columns
      .group_by { |filtered_column| filtered_column.column.then { [_1.table, _1.column] } }
      .map do |(table, db_column), grouped_filtered_columns|
      values = grouped_filtered_columns.map(&:filter)
      grouped_filtered_columns.map(&:column).map do |column|
        if column.respond_to?(:filtered_ids)
          column.filtered_ids(dossiers, values)
        else
          case table
          when 'self'
            if column.type == :date || column.type == :datetime
              dates = values
                .filter_map { |v| Time.zone.parse(v).beginning_of_day rescue nil }

              dossiers.filter_by_datetimes(db_column, dates)
            elsif db_column == "state" && values.include?("pending_correction")
              dossiers.joins(:corrections).where(corrections: DossierCorrection.pending)
            elsif db_column == "state" && values.include?("en_construction")
              dossiers.where("dossiers.#{db_column} IN (?)", values).includes(:corrections).where.not(corrections: DossierCorrection.pending)
            elsif column.type == :integer
              dossiers.where("dossiers.#{db_column} IN (?)", values.filter_map { Integer(_1) rescue nil })
            else
              dossiers.where("dossiers.#{db_column} IN (?)", values)
            end
          when 'etablissement'
            if db_column == 'entreprise_date_creation'
              dates = values
                .filter_map { |v| v.to_date rescue nil }

              dossiers
                .includes(table)
                .where(table.pluralize => { db_column => dates })
            else
              dossiers
                .includes(table)
                .filter_ilike(table, db_column, values)
            end
          when 'followers_instructeurs'
            dossiers
              .includes(:followers_instructeurs)
              .joins('INNER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
              .filter_ilike('instructeurs_users', :email, values) # ilike OK, user may want to search by *@domain
          when 'user', 'individual' # user_columns: [email], individual_columns: ['nom', 'prenom', 'gender']
            dossiers
              .includes(table)
              .filter_ilike(table, db_column, values) # ilike or where db_column == 'value' are both valid, we opted for ilike
          when 'dossier_labels'
            dossiers
              .joins(:dossier_labels)
              .where(dossier_labels: { label_id: values })
          when 'groupe_instructeur'
            dossiers
              .joins(:groupe_instructeur)
              .where(groupe_instructeur_id: values)
          end.pluck(:id)
        end
      end.reduce(:&)
    end.reduce(:&)
  end

  def self.sanitized_column(association, column)
    table = if association == 'self'
      Dossier.table_name
    elsif (association_reflection = Dossier.reflect_on_association(association))
      klass = association_reflection.klass
      # Get real db name if column has been aliased (cf etablissements.code_naf => naf)
      column = klass.attribute_aliases[column.to_s] || column
      klass.table_name
    else
      # Allow filtering on a joined table alias (which doesn’t exist
      # in the ActiveRecord domain).
      association
    end

    [table, column]
      .map { |name| ActiveRecord::Base.connection.quote_column_name(name) }
      .join('.')
  end
end
