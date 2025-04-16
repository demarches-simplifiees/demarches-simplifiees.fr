# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250415removeMisplacedAutodestructionHeaderTask do
    require 'fog/openstack'

    describe "#process" do
      subject(:process) { described_class.process('blob_key' => blob_key) }

      context "when the blob is nil" do
        let(:blob_key) { 123 }

        it "creates a TaskLog entry" do
          subject

          expect(TaskLog.count).to eq(1)
          expect(TaskLog.last.data).to eq({ "blob_key" => blob_key, "state" => "not present in db" })
        end
      end

      context "when the blob is not attached to anything" do
        let(:blob) { ActiveStorage::Blob.create!(filename: 'test.png', content_type: 'image/png', checksum: '123', byte_size: 123) }
        let(:blob_key) { blob.key }

        it "creates a TaskLog entry" do
          subject

          expect(TaskLog.count).to eq(1)
          expect(TaskLog.last.data).to eq({ "blob_key" => blob_key, "state" => "legit deleted" })
        end
      end

      context "when the blob is attached to an procedure" do
        let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }
        let(:procedure) { create(:procedure) }
        let(:attachment) { procedure.logo.attachments.first }
        let(:blob) { attachment.blob }
        let(:blob_key) { blob.key }
        let(:client) { double("client") }

        before do
          procedure.logo.attach(file)
          allow_any_instance_of(ActiveStorage::Service::DiskService).to receive(:container).and_return('a_container')
          allow_any_instance_of(ActiveStorage::Service::DiskService).to receive(:client).and_return(client)
        end

        context "and is lost" do
          before do
            allow(client).to receive(:head_object).and_raise(::Fog::OpenStack::Storage::NotFound)
          end

          it "creates a TaskLog entry" do
            subject

            expect(TaskLog.count).to eq(1)
            expect(TaskLog.last.data).to eq({ "blob_key" => blob_key, "name" => "logo", "record_id" => procedure.id, "record_type" => "Procedure", "state" => "lost" })
          end
        end
      end

      context "when the blob belongs to a champ" do
        let(:procedure) { create(:procedure_with_dossiers, types_de_champ_public: [{ type: :piece_justificative, libelle: 'Justificatif de domicile', stable_id: 3 }]) }
        let(:dossier) { procedure.dossiers.first }
        let(:champ_pj) { dossier.champs.first }
        let(:attachment) { champ_pj.piece_justificative_file.attachments.first }
        let(:blob) { attachment.blob }
        let(:blob_key) { blob.key }
        let(:client) { double("client") }

        before do
          file = fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png')
          champ_pj.piece_justificative_file.attach(file)
          allow_any_instance_of(ActiveStorage::Service::DiskService).to receive(:container).and_return('a_container')
          allow_any_instance_of(ActiveStorage::Service::DiskService).to receive(:client).and_return(client)
        end

        context "and is lost" do
          before do
            allow(client).to receive(:head_object).and_raise(::Fog::OpenStack::Storage::NotFound)
          end

          it "creates a TaskLog entry" do
            subject

            expect(TaskLog.count).to eq(1)
            expect(TaskLog.last.data).to eq({
              "email" => "default_user@user.com",
              "state" => "lost",
              "blob_key" => blob.key,
              "dossier_id" => dossier.id,
              "dossier_state" => dossier.state,
              "procedure_id" => procedure.id,
              "champ_libelle" => "Justificatif de domicile",
              "procedure_libelle" => procedure.libelle
            })
          end
        end

        context "and is not lost but will autodestruct" do
          before do
            payload = double("payload", headers: { "x-delete-at" => 666 })
            allow(client).to receive(:head_object).and_return(payload)
          end

          it 'removed the autodestruction header' do
            expect(client).to receive(:post_object)
              .with('a_container', blob.key, { 'Content-Type' => blob.content_type })

            subject

            expect(TaskLog.count).to eq(1)
            expect(TaskLog.last.data).to eq({ "state" => "saved", "blob_key" => blob.key })
          end
        end

        context "and is not lost and will not autodestruct" do
          before do
            payload = double("payload", headers: {})
            allow(client).to receive(:head_object).and_return(payload)
          end

          it 'does not remove the autodestruction header' do
            expect(client).not_to receive(:post_object)

            subject

            expect(TaskLog.count).to eq(1)
            expect(TaskLog.last.data).to eq({ "state" => "not flagged", "blob_key" => blob.key })
          end
        end
      end
    end
  end
end
