class ExpiredDossiersDeletionService
  def self.process_expired_dossiers_brouillon
    send_brouillon_expiration_notices
    delete_expired_brouillons_and_notify
  end

  def self.process_expired_dossiers_en_construction
    send_en_construction_expiration_notices
    delete_expired_en_construction_and_notify
  end

  def self.process_expired_dossiers_termine
    send_termine_expiration_notices
    delete_expired_termine_and_notify
  end

  def self.send_brouillon_expiration_notices
    dossiers_close_to_expiration = Dossier
      .brouillon_close_to_expiration
      .without_brouillon_expiration_notice_sent

    user_notifications = group_by_user_email(dossiers_close_to_expiration, state: :brouillon, action: :near_expiration)

    dossiers_close_to_expiration.update_all(brouillon_close_to_expiration_notice_sent_at: Time.zone.now)

    user_notifications.each do |(email, dossiers)|
      DossierMailer.notify_brouillon_near_deletion(
        dossiers,
        email
      ).deliver_later
    end
  end

  def self.send_en_construction_expiration_notices
    send_expiration_notices(
      Dossier.en_construction_close_to_expiration.without_en_construction_expiration_notice_sent,
      state: :en_construction, action: :near_expiration
    )
  end

  def self.send_termine_expiration_notices
    send_expiration_notices(
      Dossier.termine_close_to_expiration.without_termine_expiration_notice_sent,
      state: :termine, action: :near_expiration
    )
  end

  def self.delete_expired_brouillons_and_notify
    user_notifications = group_by_user_email(Dossier.brouillon_expired, state: :brouillon, action: :expired_destroy)
      .map { |(email, dossiers)| [email, dossiers.map(&:hash_for_deletion_mail)] }

    Dossier.brouillon_expired.destroy_all

    user_notifications.each do |(email, dossiers_hash)|
      DossierMailer.notify_brouillon_deletion(
        dossiers_hash,
        email
      ).deliver_later
    end
  end

  def self.delete_expired_en_construction_and_notify
    delete_expired_and_notify(Dossier.en_construction_expired, state: :en_construction, action: :expired_destroy)
  end

  def self.delete_expired_termine_and_notify
    delete_expired_and_notify(Dossier.termine_expired, state: :termine, action: :expired_destroy)
  end

  private

  def self.send_expiration_notices(dossiers, state:, action:)
    user_notifications = group_by_user_email(dossiers, state: state, action: action)
    administration_notifications = group_by_fonctionnaire_email(dossiers, state: state, action: action)

    if state == :en_construction
      dossiers.update_all(en_construction_close_to_expiration_notice_sent_at: Time.zone.now)
    else
      dossiers.update_all(termine_close_to_expiration_notice_sent_at: Time.zone.now)
    end

    user_notifications.each do |(email, dossiers)|
      DossierMailer.notify_near_deletion_to_user(dossiers, email).deliver_later
    end
    administration_notifications.each do |(email, dossiers)|
      DossierMailer.notify_near_deletion_to_administration(dossiers, email).deliver_later
    end
  end

  def self.delete_expired_and_notify(dossiers, state:, action:)
    user_notifications = group_by_user_email(dossiers, state: state, action: action)
      .map { |(email, dossiers)| [email, dossiers.map(&:id)] }
    administration_notifications = group_by_fonctionnaire_email(dossiers, state: state, action: action)
      .map { |(email, dossiers)| [email, dossiers.map(&:id)] }

    deleted_dossier_ids = []
    dossiers.find_each do |dossier|
      if dossier.expired_keep_track_and_destroy!
        deleted_dossier_ids << dossier.id
      end
    end
    user_notifications.each do |(email, dossier_ids)|
      dossier_ids = dossier_ids.intersection(deleted_dossier_ids)
      if dossier_ids.present?
        DossierMailer.notify_automatic_deletion_to_user(
          DeletedDossier.where(dossier_id: dossier_ids).to_a,
          email
        ).deliver_later
      end
    end
    administration_notifications.each do |(email, dossier_ids)|
      dossier_ids = dossier_ids.intersection(deleted_dossier_ids)
      if dossier_ids.present?
        DossierMailer.notify_automatic_deletion_to_administration(
          DeletedDossier.where(dossier_id: dossier_ids).to_a,
          email
        ).deliver_later
      end
    end
  end

  def self.group_by_user_email(dossiers, state:, action:)
    dossiers
      .visible_by_user
      .with_notifiable_procedure(to: :user, state: state, action: action)
      .includes(:user, :procedure)
      .group_by(&:user)
      .map { |(user, dossiers)| [user.email, dossiers] }
  end

  def self.group_by_fonctionnaire_email(dossiers, state:, action:)
    dossiers
      .visible_by_user
      .with_notifiable_procedure(to: :administration, state: state, action: action)
      .includes(:followers_instructeurs, procedure: [:administrateurs])
      .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |dossier, h|
        (dossier.followers_instructeurs + dossier.procedure.administrateurs).each { |destinataire| h[destinataire.email] << dossier }
      end
      .map { |(email, dossiers)| [email, dossiers.to_a] }
  end
end
