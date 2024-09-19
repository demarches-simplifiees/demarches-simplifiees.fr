# frozen_string_literal: true

# We are going to confirm the various email addresses of the users in the system.
# User model needs their email_verified_at attribute to be set in order to receive emails.
# This task sets the email_verified_at attribute to the current time for all users to be backward compatible
# See https://github.com/demarches-simplifiees/demarches-simplifiees.fr/issues/10450
module Maintenance
  class PrefillUserEmailVerifiedAtTask < MaintenanceTasks::Task
    def collection
      User.in_batches
    end

    def process(batch_of_users)
      batch_of_users.update_all(email_verified_at: Time.zone.now)
    end
  end
end
