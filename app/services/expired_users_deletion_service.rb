class ExpiredUsersDeletionService
  def self.process_expired
    users = find_expired_user
    users.find_each do |user|
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
end
