# frozen_string_literal: true

RSpec.shared_examples 'a job retrying transient errors' do |job_class = described_class|
  ExconErrorJob = Class.new(job_class) do
    def perform
      raise Excon::Error::InternalServerError, 'msg'
    end
  end if !defined?(ExconErrorJob)

  StandardErrorJob = Class.new(job_class) do
    def perform
      raise StandardError
    end
  end if !defined?(StandardErrorJob)

  context 'when a transient network error is raised' do
    it 'makes 5 attempts before raising the exception up' do
      assert_performed_jobs 5 do
        ExconErrorJob.perform_later rescue Excon::Error::InternalServerError
      end
    end
  end

  context 'when another type of error is raised' do
    it 'makes only 1 attempt before raising the exception up' do
      assert_performed_jobs 1 do
        StandardErrorJob.perform_later rescue StandardError
      end
    end
  end
end
