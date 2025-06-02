# frozen_string_literal: true

describe ActiveJob::RetryOnTransientErrors do
  # rubocop:disable Rails/ApplicationJob
  class Job < ActiveJob::Base
    include ActiveJob::RetryOnTransientErrors
  end
  # rubocop:enable Rails/ApplicationJob

  it_behaves_like 'a job retrying transient errors', Job
end
