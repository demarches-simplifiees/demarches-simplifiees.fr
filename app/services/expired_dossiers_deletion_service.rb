class ExpiredDossiersDeletionService
  def self.process_expired_dossiers_brouillon
    send_brouillon_expiration_notices
    delete_expired_brouillons_and_notify
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
end
