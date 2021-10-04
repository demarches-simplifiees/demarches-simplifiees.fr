class ExportJob < ApplicationJob
  queue_as :exports

  discard_on ActiveRecord::RecordNotFound

  def perform(export)
    export.compute
  end
end
