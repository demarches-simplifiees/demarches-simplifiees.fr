module CredentialsSyncableConcern
  extend ActiveSupport::Concern

  included do
    after_update :sync_credentials
  end

  def sync_credentials
    if saved_change_to_email? || saved_change_to_encrypted_password?
      return force_sync_credentials
    end
    true
  end

  def force_sync_credentials
    SyncCredentialsService.new(self.class, email_before_last_save, email, encrypted_password).change_credentials!
  end
end
