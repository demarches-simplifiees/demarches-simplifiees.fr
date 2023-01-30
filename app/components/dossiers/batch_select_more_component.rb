class Dossiers::BatchSelectMoreComponent < ApplicationComponent
  def initialize(dossiers_count:, filtered_sorted_ids:)
    @dossiers_count = dossiers_count
    @filtered_sorted_ids = filtered_sorted_ids
  end
end
