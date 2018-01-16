namespace :'2017_10_06_set_follow_date' do
  task set: :environment do
    set_default_date_to_champs_and_pieces_justificatives
    set_all_dossiers_as_read
    apply_legacy_notification_to_new_system
  end

  def set_default_date_to_champs_and_pieces_justificatives
    ActiveRecord::Base.connection
      .execute('UPDATE champs SET created_at = dossiers.created_at, updated_at = dossiers.updated_at FROM dossiers where champs.dossier_id = dossiers.id')

    PieceJustificative.includes(:dossier).where(created_at: nil).each do |piece_justificative|
      piece_justificative.update_attribute('created_at', piece_justificative.dossier.created_at)
    end

    ActiveRecord::Base.connection
      .execute('UPDATE pieces_justificatives SET updated_at = created_at')
  end

  def set_all_dossiers_as_read
    Gestionnaire.includes(:follows).all.each do |gestionnaire|
      gestionnaire.follows.update_all(
        demande_seen_at: gestionnaire.current_sign_in_at,
        annotations_privees_seen_at: gestionnaire.current_sign_in_at,
        avis_seen_at: gestionnaire.current_sign_in_at,
        messagerie_seen_at: gestionnaire.current_sign_in_at
      )
    end
  end

  def apply_legacy_notification_to_new_system
    Notification.joins(dossier: :follows).unread.each do |notification|
      if notification.demande?
        notification.dossier.follows.update_all(demande_seen_at: notification.created_at)
      end

      if notification.annotations_privees?
        notification.dossier.follows.update_all(annotations_privees_seen_at: notification.created_at)
      end

      if notification.avis?
        notification.dossier.follows.update_all(avis_seen_at: notification.created_at)
      end

      if notification.messagerie?
        notification.dossier.follows.update_all(messagerie_seen_at: notification.created_at)
      end
    end
  end
end
