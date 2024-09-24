# frozen_string_literal: true

class BatchOperationEnqueueAllJob < ApplicationJob
  queue_as :mailers # hotfix

  def perform(batch_operation)
    batch_operation.enqueue_all
  end
end
