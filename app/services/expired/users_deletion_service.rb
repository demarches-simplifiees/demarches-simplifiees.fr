class Expired::UsersDeletionService
  include MailRateLimitable

  RETENTION_AFTER_NOTICE_IN_WEEK = 2
  EXPIRABLE_AFTER_IN_YEAR = 2

  def process_expired
    [expiring_users_without_dossiers, expiring_users_with_dossiers].each do |expiring_segment|
      delete_expired_users(expiring_segment)
      send_inactive_close_to_expiration_notice(expiring_segment)
    end
  end

  private

  def send_inactive_close_to_expiration_notice(users)
    to_notify_only(users).in_batches do |batch|
      batch.each do |user|
        safe_send_email(UserMailer.notify_inactive_close_to_deletion(user))
      end
      batch.update_all(inactive_close_to_expiration_notice_sent_at: Time.zone.now.utc)
    end
  end

  def delete_expired_users(users)
    to_delete_only(users).find_each do |user|
      begin
        user.delete_and_keep_track_dossiers_also_delete_user(nil)
      rescue => e
        Sentry.capture_exception(e, extra: { user_id: user.id })
      end
    end
  end

  # rubocop:disable DS/Unscoped
  def expiring_users_with_dossiers
    users = User.arel_table
    dossiers = Dossier.arel_table

    User.unscoped # avoid default_scope eager_loading :export, :instructeur, :administrateur
      .where.missing(:expert, :instructeur, :administrateur)
      .joins(
        users.join(dossiers, Arel::Nodes::InnerJoin)
          .on(users[:id].eq(dossiers[:user_id])
          .and(dossiers[:state].not_eq(Dossier.states.fetch(:en_instruction))))
          .join_sources
      )
      .having('MAX(dossiers.created_at) < ?', EXPIRABLE_AFTER_IN_YEAR.years.ago)
      .group('users.id')
  end

  def expiring_users_without_dossiers
    User.unscoped
      .where.missing(:expert, :instructeur, :administrateur, :dossiers)
      .where(last_sign_in_at: ..EXPIRABLE_AFTER_IN_YEAR.years.ago)
  end
  # rubocop:enable DS/Unscoped

  def to_notify_only(users)
    users.where(inactive_close_to_expiration_notice_sent_at: nil)
      .limit(limit)
  end

  def to_delete_only(users)
    users.where.not(inactive_close_to_expiration_notice_sent_at: RETENTION_AFTER_NOTICE_IN_WEEK.weeks.ago..)
  end

  def limit
    (ENV['EXPIRE_USER_DELETION_JOB_LIMIT'] || 10_000).to_i
  end
end
