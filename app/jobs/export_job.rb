class ExportJob < ApplicationJob
  queue_as :exports

  def perform(export)
    export.compute
  end
end
