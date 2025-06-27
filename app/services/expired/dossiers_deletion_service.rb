# frozen_string_literal: true

class Expired::DossiersDeletionService < Expired::MailRateLimiter
  BROUILLON_DELETION_EMAILS_LIMIT_PER_DAY = ENV.fetch("BROUILLON_DELETION_EMAILS_LIMIT_PER_DAY", 10_000).to_i
  BATCH_SIZE = ENV.fetch("EXPIRED_DOSSIERS_BATCH_SIZE", 1000).to_i

  def process_never_touched_dossiers_brouillon; delete_never_touched_brouillons; end

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
      .limit(BROUILLON_DELETION_EMAILS_LIMIT_PER_DAY)

    dossiers_close_to_expiration.includes(:user, :procedure).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      user_notifications = batch
        .group_by(&:user)
        .map { |(user, dossiers)| [user.email, dossiers] }

      user_notifications.each do |(email, dossiers)|
        mail = DossierMailer.notify_brouillon_near_deletion(
          dossiers,
          email
        )

        send_with_delay(mail)
        Dossier.where(id: dossiers.map(&:id)).update_all(brouillon_close_to_expiration_notice_sent_at: Time.zone.now)
      end
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

  def delete_never_touched_brouillons
    Dossier.never_touched_brouillon_expired.in_batches.destroy_all
  end

  def delete_expired_brouillons_and_notify
    Dossier.brouillon_expired.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      user_notifications = batch
        .group_by(&:user)
        .map { |(user, dossiers)| [user.email, dossiers.map(&:hash_for_deletion_mail)] }

      Dossier.where(id: batch.map(&:id)).destroy_all

      user_notifications.each do |(email, dossiers_hash)|
        mail = DossierMailer.notify_brouillon_deletion(
          dossiers_hash,
          email
        )
        send_with_delay(mail)
      end
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

    hidden_dossier_ids = []
    dossiers_to_remove.find_each do |dossier|
      dossier.hide_and_keep_track!(:automatic, :expired)
      hidden_dossier_ids << dossier.id
    end
    user_notifications.each do |(email, dossier_ids)|
      dossier_ids = dossier_ids.intersection(hidden_dossier_ids)
      if dossier_ids.present?
        mail = DossierMailer.notify_automatic_deletion_to_user(
          Dossier.where(id: dossier_ids).to_a,
          email
        )
        send_with_delay(mail)
      end
    end
    administration_notifications.each do |(email, dossier_ids)|
      dossier_ids = dossier_ids.intersection(hidden_dossier_ids)
      if dossier_ids.present?
        mail = DossierMailer.notify_automatic_deletion_to_administration(
          Dossier.where(id: dossier_ids).to_a,
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
      .includes(
        :followers_instructeurs,
        procedure: {
          groupe_instructeurs: { instructeurs: :user },
          administrateurs: :user
        }
      )
      .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |dossier, h|
        dossier.followers_instructeurs.each do |instructeur|
          h[instructeur.email] << dossier
        end

        admin_emails = dossier.procedure.administrateurs.map(&:email)
        dossier.procedure.groupe_instructeurs.each do |groupe|
          groupe.instructeurs.each do |instructeur|
            if admin_emails.include?(instructeur.email)
              h[instructeur.email] << dossier
            end
          end
        end
      end.transform_values(&:to_a)
  end

  def all_user_dossiers_brouillon_close_to_expiration(user)
    user.dossiers
      .brouillon_close_to_expiration
      .without_brouillon_expiration_notice_sent
      .visible_by_user
      .with_notifiable_procedure(notify_on_closed: true)
      .includes(:user, :procedure)
  end
end
