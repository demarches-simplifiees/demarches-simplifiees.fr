# frozen_string_literal: true

class Columns::NotificationsColumn < Columns::DossierColumn
  def initialize(procedure_id:)
    super(
      procedure_id:,
      table: 'notifications',
      column: 'notifications',
      label: 'notifications',
      filterable: false,
      displayable: false
    )
  end

  def sorted_ids(dossiers, order, instructeur:, **)
    if order == 'desc'
      dossiers_id_with_notifications = dossiers.with_notifications(instructeur).order_by_notifications_importance.map(&:id)
      (dossiers_id_with_notifications + dossiers.order('dossiers.updated_at desc').ids).uniq
    else
      dossiers.order('dossiers.updated_at asc').ids
    end
  end
end
