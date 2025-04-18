# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250418sendNotificationToUsersHavingLostPjsTask do
    describe "#process" do
      subject(:process) { described_class.process }

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

          TaskLog.create(data: { blob_key: champ_pj_1.piece_justificative_file.attachments.first.key, state: 'definitely lost' })
          TaskLog.create(data: { blob_key: champ_pj_2.piece_justificative_file.attachments.first.key, state: 'definitely lost' })
        end

        it 'sends an email to the user' do
          expect(BlankMailer).to receive(:send_template).with(to: dossier.user.email, subject: "[demarches-simplifiees.fr] Action requise : pièces jointes manquantes", title: "Pièces jointes manquantes", body: /pj_1.*pj_2.*#{dossier.id}/).and_return(double(deliver_later: true))
          subject

          expect(TaskLog.pluck(:data).map { |log| log['notified'] }).to all(eq('user'))
        end

        context 'when the dossier is in en_instruction' do
          before { dossier.update(state: 'en_instruction') }

          context 'the dossier is not followed by an instructeur' do
            it 'sends an email to the user' do
              expect(BlankMailer).not_to receive(:send_template)

              subject

              expect(TaskLog.pluck(:data).map { |log| log['notified'] }).to all(eq(nil))
            end
          end

          context 'when the dossier is followed by an instructeur' do
            let(:instructeur) { create(:instructeur) }

            before { instructeur.follow(dossier) }

            it 'sends an email to the instructeur' do
              expect(BlankMailer).to receive(:send_template).with(to: instructeur.user.email, subject: "[demarches-simplifiees.fr] Action requise : pièces jointes manquantes", title: "Pièces jointes manquantes", body: /pj_1.*pj_2.*#{dossier.id}/).and_return(double(deliver_later: true))

              subject

              expect(TaskLog.pluck(:data).map { |log| log['notified'] }).to all(eq('instructeur'))
            end
          end
        end
      end
    end
  end
end
