# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250418sendNotificationToUsersHavingLostPjsTask do
    let(:email) { "user@rspec.info" }
    describe "#process" do
      subject(:process) { described_class.process(email) }

      context 'when a dossier with missing pj is in brouillon' do
        let(:procedure) do
          create(:procedure_with_dossiers, types_de_champ_public: [
            { type: :piece_justificative, libelle: 'pj_1' },
            { type: :piece_justificative, libelle: 'pj_2' }
          ])
        end
        let(:dossier) { procedure.dossiers.first }
        let(:champ_pj_1) { dossier.champs.first }
        let(:champ_pj_2) { dossier.champs.second }
        let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }

        before do
          champ_pj_1.piece_justificative_file.attach(file)
          champ_pj_2.piece_justificative_file.attach(file)

          TaskLog.create(data: { blob_key: champ_pj_1.piece_justificative_file.attachments.first.key, state: 'definitely lost', email: })
          TaskLog.create(data: { blob_key: champ_pj_2.piece_justificative_file.attachments.first.key, state: 'definitely lost', email: })
          TaskLog.create(data: { blob_key: "12/244", state: 'definitely lost', email: "other@user.com" })
        end

        it 'sends an email to the user' do
          expect(BlankMailer).to receive(:send_template).with(to: dossier.user.email, subject: "[demarches-simplifiees.fr] Action requise : pièces jointes manquantes", title: "Pièces jointes manquantes", body: /#{dossier.id}.+pj_1.*pj_2/).and_return(double(deliver_later: true))
          subject

          expect(TaskLog.where("data->>'email' = ?", email).pluck(:data).map { |log| log['notified'] }).to all(eq('user'))
          expect(TaskLog.where.not("data->>'email' = ?", email).pluck(:data).map { |log| log['notified'] }).to all(be_nil)

          expect(BlankMailer).to receive(:send_template).never
          described_class.process(email)
        end
      end
    end
  end
end
