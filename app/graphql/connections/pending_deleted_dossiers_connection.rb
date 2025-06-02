# frozen_string_literal: true

module Connections
  class PendingDeletedDossiersConnection < CursorConnection
    def cursor_for(item)
      if item.en_construction?
        cursor_from_column(item, :hidden_by_user_at)
      else
        cursor_from_column(item, :hidden_by_administration_at)
      end
    end

    private

    def resolve_nodes(before:, after:, limit:, inverted:)
      order = inverted ? :desc : :asc

      dossiers_table = Dossier.arel_table
      case_statement = dossiers_table[:state]
        .when(:en_construction)
        .then(dossiers_table[:hidden_by_user_at])
        .else(dossiers_table[:hidden_by_administration_at])

      nodes = items.order(case_statement.public_send(order)).order(dossiers_table[:id].public_send(order))
      nodes = nodes.limit(limit)

      if before.present?
        timestamp, id = timestamp_and_id_from_cursor(before)
        nodes.where("(#{case_statement.to_sql}, dossiers.id) < (?, ?)", timestamp, id)
      elsif after.present?
        timestamp, id = timestamp_and_id_from_cursor(after)
        nodes.where("(#{case_statement.to_sql}, dossiers.id) > (?, ?)", timestamp, id)
      else
        nodes
      end
    end
  end
end
