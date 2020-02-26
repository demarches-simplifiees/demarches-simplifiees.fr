class ExpiredDossiersDeletionService
  def self.process_expired_dossiers_brouillon
    send_brouillon_expiration_notices
    delete_expired_brouillons_and_notify
  end

  def self.process_expired_dossiers_en_construction
    send_en_construction_expiration_notices
    delete_expired_en_construction_and_notify
  end

  private

  def self.send_brouillon_expiration_notices
    dossiers_close_to_expiration = Dossier.brouillon_close_to_expiration
      .without_brouillon_expiration_notice_sent

    users_to_notify = {}

    dossiers_close_to_expiration
      .includes(:user, :procedure)
      .find_each do |dossier|
        users_to_notify[dossier.user.email] ||= [dossier.user, Set.new]
        users_to_notify[dossier.user.email].last.add(dossier)
      end

    users_to_notify.each_value do |(user, dossiers)|
      DossierMailer.notify_brouillon_near_deletion(user, dossiers).deliver_later
    end

    dossiers_close_to_expiration.update_all(brouillon_close_to_expiration_notice_sent_at: Time.zone.now)
  end

  def self.send_en_construction_expiration_notices
    dossiers_close_to_expiration = Dossier.en_construction_close_to_expiration
      .without_en_construction_expiration_notice_sent

    users_to_notify = {}
    administrations_to_notify = {}

    dossiers_close_to_expiration
      .includes(:user, :followers_instructeurs, procedure: [:administrateurs])
      .find_each do |dossier|
        users_to_notify[dossier.user.email] ||= [dossier.user, Set.new]
        users_to_notify[dossier.user.email].last.add(dossier)

        (dossier.followers_instructeurs + dossier.procedure.administrateurs).each do |destinataire|
          administrations_to_notify[destinataire.email] ||= [destinataire, Set.new]
          administrations_to_notify[destinataire.email].last.add(dossier)
        end
      end

    users_to_notify.each_value do |(user, dossiers)|
      DossierMailer.notify_en_construction_near_deletion(
        user,
        dossiers,
        true
      ).deliver_later
    end

    administrations_to_notify.each_value do |(destinataire, dossiers)|
      DossierMailer.notify_en_construction_near_deletion(
        destinataire,
        dossiers,
        false
      ).deliver_later
    end

    dossiers_close_to_expiration.update_all(en_construction_close_to_expiration_notice_sent_at: Time.zone.now)
  end

  def self.delete_expired_brouillons_and_notify
    dossier_to_remove = []
    users_to_notify = {}

    Dossier.brouillon_expired
      .includes(:user, :procedure)
      .find_each do |dossier|
        dossier_to_remove << dossier

        users_to_notify[dossier.user.email] ||= [dossier.user, Set.new]
        users_to_notify[dossier.user.email].last.add(dossier)
      end

    users_to_notify.each_value do |(user, dossiers)|
      DossierMailer.notify_brouillon_deletion(
        user,
        dossiers.map(&:hash_for_deletion_mail)
      ).deliver_later
    end

    dossier_to_remove.each do |dossier|
      DeletedDossier.create_from_dossier(dossier)
      dossier.destroy
    end
  end

  def self.delete_expired_en_construction_and_notify
    dossier_to_remove = []
    users_to_notify = {}
    administrations_to_notify = {}

    Dossier.en_construction_expired
      .includes(:user, :followers_instructeurs, procedure: [:administrateurs])
      .find_each do |dossier|
        dossier_to_remove << dossier

        users_to_notify[dossier.user.email] ||= [dossier.user, Set.new]
        users_to_notify[dossier.user.email].last.add(dossier)

        (dossier.followers_instructeurs + dossier.procedure.administrateurs).each do |destinataire|
          administrations_to_notify[destinataire.email] ||= [destinataire, Set.new]
          administrations_to_notify[destinataire.email].last.add(dossier)
        end
      end

    users_to_notify.each_value do |(user, dossiers)|
      DossierMailer.notify_deletion_to_user(
        user,
        dossiers.map(&:hash_for_deletion_mail)
      ).deliver_later
    end

    administrations_to_notify.each_value do |(destinataire, dossiers)|
      DossierMailer.notify_deletion_to_administration(
        destinataire,
        dossiers.map(&:hash_for_deletion_mail)
      ).deliver_later
    end

    dossier_to_remove.each do |dossier|
      DeletedDossier.create_from_dossier(dossier)
      dossier.destroy
    end
  end
end
