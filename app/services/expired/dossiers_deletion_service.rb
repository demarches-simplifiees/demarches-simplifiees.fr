class Expired::DossiersDeletionService < Expired::MailRateLimiter
  def process_expired_dossiers_brouillon
    send_brouillon_expiration_notices
    delete_expired_brouillons_and_notify
  end

  def process_expired_dossiers_en_construction
    send_en_construction_expiration_notices
    delete_expired_en_construction_and_notify
  end

  def process_expired_dossiers_termine
    send_termine_expiration_notices
    delete_expired_termine_and_notify
  end

  def send_brouillon_expiration_notices
    dossiers_close_to_expiration = Dossier
      .brouillon_close_to_expiration
      .without_brouillon_expiration_notice_sent

    user_notifications = group_by_user_email(dossiers_close_to_expiration)

    dossiers_close_to_expiration.in_batches.update_all(brouillon_close_to_expiration_notice_sent_at: Time.zone.now)

    user_notifications.each do |(email, dossiers)|
      mail = DossierMailer.notify_brouillon_near_deletion(
        dossiers,
        email
      )
      send_with_delay(mail)
    end
  end

  def send_en_construction_expiration_notices
    send_expiration_notices(
      Dossier.en_construction_close_to_expiration.without_en_construction_expiration_notice_sent,
      :en_construction_close_to_expiration_notice_sent_at
    )
  end

  def send_termine_expiration_notices
    send_expiration_notices(
      Dossier.termine_close_to_expiration.without_termine_expiration_notice_sent,
      :termine_close_to_expiration_notice_sent_at
    )
  end

  def delete_expired_brouillons_and_notify
    user_notifications = group_by_user_email(Dossier.brouillon_expired)
      .map { |(email, dossiers)| [email, dossiers.map(&:hash_for_deletion_mail)] }

    Dossier.brouillon_expired.in_batches.destroy_all

    user_notifications.each do |(email, dossiers_hash)|
      mail = DossierMailer.notify_brouillon_deletion(
        dossiers_hash,
        email
      )
      send_with_delay(mail)
    end
  end

  def delete_expired_en_construction_and_notify
    delete_expired_and_notify(Dossier.en_construction_expired)
  end

  def delete_expired_termine_and_notify
    delete_expired_and_notify(Dossier.termine_expired, notify_on_closed_procedures_to_user: true)
  end

  private

  def send_expiration_notices(dossiers_close_to_expiration, close_to_expiration_flag)
    user_notifications = group_by_user_email(dossiers_close_to_expiration)
    administration_notifications = group_by_fonctionnaire_email(dossiers_close_to_expiration)

    dossiers_close_to_expiration.in_batches.update_all(close_to_expiration_flag => Time.zone.now)

    user_notifications.each do |(email, dossiers)|
      mail = DossierMailer.notify_near_deletion_to_user(dossiers, email)
      send_with_delay(mail)
    end
    administration_notifications.each do |(email, dossiers)|
      mail = DossierMailer.notify_near_deletion_to_administration(dossiers, email)
      send_with_delay(mail)
    end
  end

  def delete_expired_and_notify(dossiers_to_remove, notify_on_closed_procedures_to_user: false)
    user_notifications = group_by_user_email(dossiers_to_remove, notify_on_closed_procedures_to_user: notify_on_closed_procedures_to_user)
      .map { |(email, dossiers)| [email, dossiers.map(&:id)] }
    administration_notifications = group_by_fonctionnaire_email(dossiers_to_remove)
      .map { |(email, dossiers)| [email, dossiers.map(&:id)] }

    deleted_dossier_ids = []
    dossiers_to_remove.find_each do |dossier|
      if dossier.expired_keep_track_and_destroy!
        deleted_dossier_ids << dossier.id
      end
    end
    user_notifications.each do |(email, dossier_ids)|
      dossier_ids = dossier_ids.intersection(deleted_dossier_ids)
      if dossier_ids.present?
        mail = DossierMailer.notify_automatic_deletion_to_user(
          DeletedDossier.where(dossier_id: dossier_ids).to_a,
          email
        )
        send_with_delay(mail)
      end
    end
    administration_notifications.each do |(email, dossier_ids)|
      dossier_ids = dossier_ids.intersection(deleted_dossier_ids)
      if dossier_ids.present?
        mail = DossierMailer.notify_automatic_deletion_to_administration(
          DeletedDossier.where(dossier_id: dossier_ids).to_a,
          email
        )
        send_with_delay(mail)
      end
    end
  end

  def group_by_user_email(dossiers, notify_on_closed_procedures_to_user: false)
    dossiers
      .visible_by_user
      .with_notifiable_procedure(notify_on_closed: notify_on_closed_procedures_to_user)
      .includes(:user, :procedure)
      .group_by(&:user)
      .map { |(user, dossiers)| [user.email, dossiers] }
  end

  def group_by_fonctionnaire_email(dossiers)
    dossiers
      .visible_by_administration
      .with_notifiable_procedure(notify_on_closed: true)
      .includes(:followers_instructeurs, procedure: [:administrateurs])
      .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |dossier, h|
        (dossier.followers_instructeurs + dossier.procedure.administrateurs).each { |destinataire| h[destinataire.email] << dossier }
      end
      .map { |(email, dossiers)| [email, dossiers.to_a] }
  end
end
