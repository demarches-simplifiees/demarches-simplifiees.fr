# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250417setDefinitelyLostStateToCorrespondingTaskLogsTask do
    describe "#process" do
      subject(:process) { described_class.process('blob_key' => blob_key) }

      context "when the blob is nil" do
        let(:blob_key) { '123' }

        before do
          TaskLog.create!(data: { blob_key:, state: 'a state' })
        end

        it "creates a TaskLog entry" do
          subject

          expect(TaskLog.pluck(:data)).to eq([{ "blob_key" => "123", "state" => "not present in db" }])
        end
      end

      context "when the blob is in db" do
        let(:blob) { ActiveStorage::Blob.create!(filename: 'test.png', content_type: 'image/png', checksum: '123', byte_size: 123) }
        let(:blob_key) { blob.key }

        before do
          TaskLog.create!(data: { blob_key:, state: 'a state' })
        end

        it "updates the TaskLog entry to state 'definitely lost'" do
          subject

          expect(TaskLog.pluck(:data)).to eq([{ "blob_key" => blob_key, "state" => "definitely lost" }])
        end
      end
    end
  end
end
