# frozen_string_literal: true

class ExportJob < ApplicationJob
  queue_as :exports

  discard_on ActiveRecord::RecordNotFound

  def max_run_time
    Export::MAX_DUREE_GENERATION
  end

  def perform(export)
    return if export.generated?

    Sentry.set_tags(procedure: export.procedure.id)

    export.compute_with_safe_stale_for_purge do
      export.compute
    end
  end
end
