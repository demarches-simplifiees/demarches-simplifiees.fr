# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250418sendNotificationToInstructeursHavingLostPjsTask do
    let(:email) { "user@rspec.info" }

    describe "#process" do
      subject(:process) { described_class.process(procedure_id) }

      context 'when a dossier with missing pj is in construction' do
        let(:procedure) do
          create(:procedure_with_dossiers, types_de_champ_public: [
            { type: :piece_justificative, libelle: 'pj_1' },
            { type: :piece_justificative, libelle: 'pj_2' },
          ])
        end
        let(:procedure_id) { procedure.id }
        let(:dossier) { procedure.dossiers.first }
        let(:instructeur) { create(:instructeur) }
        let(:champ_pj_1) { dossier.champs.first }
        let(:champ_pj_2) { dossier.champs.second }
        let(:file) { fixture_file_upload('spec/fixtures/files/logo_test_procedure.png', 'image/png') }

        before do
          dossier.followers_instructeurs << instructeur

          champ_pj_1.piece_justificative_file.attach(file)
          champ_pj_2.piece_justificative_file.attach(file)

          dossier.passer_en_construction!
          dossier.passer_en_instruction!(instructeur:)

          TaskLog.create(data: { blob_key: champ_pj_1.piece_justificative_file.attachments.first.key, state: 'definitely lost', procedure_id: })
          TaskLog.create(data: { blob_key: champ_pj_2.piece_justificative_file.attachments.first.key, state: 'definitely lost', procedure_id: })
          TaskLog.create(data: { blob_key: "12/244", state: 'definitely lost', email: "other@user.com" })
        end

        it 'sends an email to the instructeur' do
          expect(BlankMailer).to receive(:send_template).with(to: dossier.followers_instructeurs.first.email, subject: "[demarche.numerique.gouv.fr] Action requise : pièces jointes manquantes", title: "Pièces jointes manquantes", body: /pj_1.*pj_2.*#{dossier.id}/).and_return(double(deliver_later: true))
          subject

          expect(TaskLog.where("data->>'procedure_id' = ?", procedure_id.to_s).pluck(:data).map { |log| log['instructeur_notified'] }).to all(be_truthy)
          expect(TaskLog.where.not("data->>'procedure_id' = ?", procedure_id.to_s).pluck(:data).map { |log| log['instructeur_notified'] }).to all(be_nil)

          expect(BlankMailer).to receive(:send_template).never
          described_class.process(email)
        end
      end
    end
  end
end
