class PurgeStaleExportsJob < ApplicationJob
  queue_as :cron

  def perform
    Export.stale.destroy_all
  end
end
