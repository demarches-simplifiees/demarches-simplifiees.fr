# frozen_string_literal: true

class DestroyRecordLaterJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound
  queue_as :low # destroy later, will be done when possible

  def perform(record)
    record.destroy
  end
end
