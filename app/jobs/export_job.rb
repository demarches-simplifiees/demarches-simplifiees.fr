class ExportJob < ApplicationJob
  def perform(export)
    export.compute
  end
end
