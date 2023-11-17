class Expired::UsersDeletionService < Expired::MailRateLimiter
  def process_expired
    # we are working on two dataset because we apply two incompatible join on the same query
    #   inner join on users not having dossier.en_instruction [so we do not destroy users with dossiers.en_instruction]
    #   outer join on users not having dossier at all [so we destroy users without dossiers]
    [expired_users_without_dossiers, expired_users_with_dossiers].each do |expired_segment|
      delete_notified_users(expired_segment)
      send_inactive_close_to_expiration_notice(expired_segment)
    end
  end

  private

  def send_inactive_close_to_expiration_notice(users)
    to_notify_only(users).in_batches do |batch|
      batch.each do |user|
        send_with_delay(UserMailer.notify_inactive_close_to_deletion(user))
      end
      batch.update_all(inactive_close_to_expiration_notice_sent_at: Time.zone.now.utc)
    end
  end

  def delete_notified_users(users)
    only_notified(users).find_each do |user|
      begin
        user.delete_and_keep_track_dossiers_also_delete_user(nil)
      rescue => e
        Sentry.capture_exception(e, extra: { user_id: user.id })
      end
    end
  end

  # rubocop:disable DS/Unscoped
  def expired_users_with_dossiers
    expired_users
      .joins(:dossiers)
      .group("users.id")
      .having("NOT 'en_instruction' = ANY(ARRAY_AGG(dossiers.state))")
  end

  def expired_users_without_dossiers
    expired_users.where.missing(:dossiers)
  end

  def expired_users
    User.unscoped
      .where.missing(:expert, :instructeur, :administrateur)
      .where(last_sign_in_at: ..Expired::INACTIVE_USER_RETATION_IN_YEAR.years.ago)
  end
  # rubocop:enable DS/Unscoped

  def to_notify_only(users)
    users.where(inactive_close_to_expiration_notice_sent_at: nil)
      .limit(daily_limit) # ensure to not send too much email
  end

  def only_notified(users)
    users.where.not(inactive_close_to_expiration_notice_sent_at: Expired::REMAINING_WEEKS_BEFORE_EXPIRATION.weeks.ago..)
      .limit(daily_limit) # event if we do not send email, avoid to destroy 800k user in one batch
  end

  def daily_limit
    (ENV['EXPIRE_USER_DELETION_JOB_LIMIT'] || 10_000).to_i
  end
end
