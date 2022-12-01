class Dossiers::BatchAlertComponent < ApplicationComponent
  attr_reader :batch

  def initialize(batch:, procedure:)
    @batch = batch
    @procedure = procedure
  end
end
