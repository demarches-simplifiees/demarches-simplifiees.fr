# frozen_string_literal: true

describe ActiveStorage::BaseJob do
  it_behaves_like 'a job retrying transient errors'
end
