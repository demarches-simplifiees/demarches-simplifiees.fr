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
      dossiers_id_with_notifications = dossiers.merge(instructeur.followed_dossiers).with_notifications.ids
      dossiers_id_with_notifications_v2 = dossiers.with_notifications_v2.order_by_notifications_importance.map(&:id)
      if order == 'desc'
        (dossiers_id_with_notifications_v2 + dossiers_id_with_notifications + dossiers.order('dossiers.updated_at desc').ids).uniq
      else
        dossiers.order('dossiers.updated_at asc').ids
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
    values_by_column = filtered_columns.group_by(&:column).transform_values { _1.map(&:filter) }

    values_by_column.map { |column, values| column.filtered_ids(dossiers, values) }.reduce(:intersection)
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
