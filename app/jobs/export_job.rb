class ExportJob < ApplicationJob
  queue_as :exports

  discard_on ActiveRecord::RecordNotFound

  def perform(export)
    return if export.generated?

    export.compute_with_safe_stale_for_purge do
      export.compute
    end
  end
end
