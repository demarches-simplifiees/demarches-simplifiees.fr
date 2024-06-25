# frozen_string_literal: true

# We are going to confirm the various email addresses of the users in the system.
# Individual model (mandant) needs their email_verified_at attribute to be set in order to receive emails.
# This task sets the email_verified_at attribute to the current time for all the individual to be backward compatible
# See https://github.com/demarches-simplifiees/demarches-simplifiees.fr/issues/10450
module Maintenance
  class PrefillIndividualEmailVerifiedAtTask < MaintenanceTasks::Task
    def collection
      Individual.in_batches
    end

    def process(batch_of_individuals)
      batch_of_individuals.update_all(email_verified_at: Time.zone.now)
    end
  end
end
