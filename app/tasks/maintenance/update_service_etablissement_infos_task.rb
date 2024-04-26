# frozen_string_literal: true

module Maintenance
  class UpdateServiceEtablissementInfosTask < MaintenanceTasks::Task
    # No more 20 geocoding by 10 seconds window
    THROTTLE_LIMIT = 20
    THROTTLE_PERIOD = 10.seconds

    @@request_count = 0
    @@period_start = Time.current

    throttle_on(backoff: THROTTLE_LIMIT) do
      if Time.current - @@period_start > THROTTLE_PERIOD
        @@request_count = 0
        @@period_start = Time.current
      end

      @@request_count += 1
      @@request_count > THROTTLE_LIMIT
    end

    def collection
      Service.where.not(siret: nil)
    end

    def process(service)
      APIEntreprise::ServiceJob.perform_now(service.id)
    end

    def count
      collection.count
    end
  end
end
