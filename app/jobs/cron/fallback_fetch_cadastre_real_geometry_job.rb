# frozen_string_literal: true

class Cron::FallbackFetchCadastreRealGeometryJob < Cron::CronJob
  self.schedule_expression = "every hour"

  queue_as :low

  def perform
    GeoArea.pending_cadastre
      .limit(1_000)
      .find_each(batch_size: 100) do |geo_area|
      FetchCadastreRealGeometryJob.set(wait:).perform_later(geo_area)
    end
  end

  private

  def wait = rand(0..1.hour)
end
