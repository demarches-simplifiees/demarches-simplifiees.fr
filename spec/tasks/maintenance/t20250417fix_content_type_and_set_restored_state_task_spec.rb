# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250417fixContentTypeAndSetRestoredStateTask do
    require 'fog/openstack'

    describe "#process" do
      subject(:process) { described_class.process('blob_key' => blob_key) }

      context "when the blob is nil" do
        let(:blob_key) { '123' }

        before do
          TaskLog.create!(data: { blob_key: 'another_key', state: 'another state' })
          TaskLog.create!(data: { blob_key:, state: 'a state', another_key: 'another value' })
        end

        it "creates a TaskLog entry" do
          subject

          expect(TaskLog.pluck(:data)).to match_array([
            { "blob_key" => "another_key", "state" => "another state" },
            { "blob_key" => "123", "state" => "not present in db", "another_key" => "another value" },
          ])
        end
      end

      context "when the blob is in db" do
        let(:blob) { ActiveStorage::Blob.create!(filename: 'test.png', content_type: 'image/png', checksum: '123', byte_size: 123) }
        let(:blob_key) { blob.key }
        let(:client) { double("client") }

        before do
          allow_any_instance_of(blob.service.class).to receive(:container).and_return('a_container')
          allow_any_instance_of(blob.service.class).to receive(:client).and_return(client)

          TaskLog.create!(data: { blob_key:, state: 'a state' })
        end

        context "when the blob is restored" do
          before { allow(client).to receive(:post_object) }

          it "updates the TaskLog entry to state 'restored'" do
            subject

            expect(TaskLog.count).to eq(1)
            expect(TaskLog.last.data).to eq({ "blob_key" => blob_key, "state" => "restored" })
          end
        end

        context "when the blob is not found in openstack" do
          before { allow(client).to receive(:post_object).and_raise(::Fog::OpenStack::Storage::NotFound) }

          it "updates the TaskLog entry to state 'restoration failed'" do
            subject

            expect(TaskLog.count).to eq(1)
            expect(TaskLog.last.data).to eq({ "blob_key" => blob_key, "state" => "restoration failed" })
          end
        end
      end
    end
  end
end
