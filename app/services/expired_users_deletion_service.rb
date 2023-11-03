class ExpiredUsersDeletionService
  RETENTION_AFTER_NOTICE = 2.weeks

  def self.process_expired
    delete_expired_users
    send_inactive_close_to_expiration_notice
  end

  def self.send_inactive_close_to_expiration_notice
    expiring_users_to_notify.in_batches do |batch|
      batch.each do |user|
        UserMailer.notify_inactive_close_to_deletion(user).perform_later
      end
      batch.update_all(inactive_close_to_expiration_notice_sent_at: Time.zone.now.utc)
    end
  end

  def self.delete_expired_users
    expiring_user_notified.find_each do |user|
      user.delete_and_keep_track_dossiers_also_delete_user(nil)
    end
  end

  # rubocop:disable DS/Unscoped
  def self.expiring_users
    User.unscoped # avoid default_scope eager_loading :export, :instructeur, :administrateur
      .joins(:dossiers)
      .having('MAX(dossiers.created_at) < ?', 2.years.ago)
      .group('users.id')
  end
  # rubocop:enable DS/Unscoped

  def self.expiring_users_to_notify
    expiring_users.where(inactive_close_to_expiration_notice_sent_at: nil)
  end

  def self.expiring_user_notified
    expiring_users.where.not(inactive_close_to_expiration_notice_sent_at: RETENTION_AFTER_NOTICE.ago..)
  end
end
