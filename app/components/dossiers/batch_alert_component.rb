class Dossiers::BatchAlertComponent < ApplicationComponent
  attr_reader :batch

  def initialize(batch:, procedure:)
    @batch = batch
    @procedure = procedure
  end

  def set_seen_at!
    @batch.seen_at = Time.zone.now
    @batch.save
  end
end
