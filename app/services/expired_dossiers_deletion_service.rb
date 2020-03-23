class ExpiredDossiersDeletionService
  def self.process_expired_dossiers_brouillon
    send_brouillon_expiration_notices
    delete_expired_brouillons_and_notify
  end

  def self.process_expired_dossiers_en_construction
    send_en_construction_expiration_notices
    delete_expired_en_construction_and_notify
  end

  def self.send_brouillon_expiration_notices
    dossiers_close_to_expiration = Dossier
      .brouillon_close_to_expiration
      .without_brouillon_expiration_notice_sent

    dossiers_close_to_expiration
      .includes(:user, :procedure)
      .group_by(&:user)
      .each do |(user, dossiers)|
        DossierMailer.notify_brouillon_near_deletion(
          dossiers,
          user.email
        ).deliver_later
      end

    dossiers_close_to_expiration.update_all(brouillon_close_to_expiration_notice_sent_at: Time.zone.now)
  end

  def self.send_en_construction_expiration_notices
    dossiers_close_to_expiration = Dossier
      .en_construction_close_to_expiration
      .without_en_construction_expiration_notice_sent

    dossiers_close_to_expiration
      .includes(:user)
      .group_by(&:user)
      .each do |(user, dossiers)|
        DossierMailer.notify_en_construction_near_deletion_to_user(
          dossiers,
          user.email
        ).deliver_later
      end

    group_by_fonctionnaire_email(dossiers_close_to_expiration).each do |(email, dossiers)|
      DossierMailer.notify_en_construction_near_deletion_to_administration(
        dossiers,
        email
      ).deliver_later
    end

    dossiers_close_to_expiration.update_all(en_construction_close_to_expiration_notice_sent_at: Time.zone.now)
  end

  def self.delete_expired_brouillons_and_notify
    dossiers_to_remove = Dossier.brouillon_expired

    dossiers_to_remove
      .includes(:user, :procedure)
      .group_by(&:user)
      .each do |(user, dossiers)|
        DossierMailer.notify_brouillon_deletion(
          dossiers.map(&:hash_for_deletion_mail),
          user.email
        ).deliver_later
      end

    dossiers_to_remove.each do |dossier|
      DeletedDossier.create_from_dossier(dossier)
      dossier.destroy
    end
  end

  def self.delete_expired_en_construction_and_notify
    dossiers_to_remove = Dossier.en_construction_expired

    dossiers_to_remove.each do |dossier|
      DeletedDossier.create_from_dossier(dossier)
    end

    dossiers_to_remove
      .includes(:user)
      .group_by(&:user)
      .each do |(user, dossiers)|
        DossierMailer.notify_automatic_deletion_to_user(
          DeletedDossier.where(dossier_id: dossiers.map(&:id)),
          user.email
        ).deliver_later
      end

    self.group_by_fonctionnaire_email(dossiers_to_remove).each do |(email, dossiers)|
      DossierMailer.notify_automatic_deletion_to_administration(
        DeletedDossier.where(dossier_id: dossiers.map(&:id)),
        email
      ).deliver_later
    end

    dossiers_to_remove.destroy_all
  end

  private

  def self.group_by_fonctionnaire_email(dossiers)
    dossiers
      .includes(:followers_instructeurs, procedure: [:administrateurs])
      .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |dossier, h|
        (dossier.followers_instructeurs + dossier.procedure.administrateurs).each { |destinataire| h[destinataire.email] << dossier }
      end
  end
end
