# frozen_string_literal: true

describe NotificationService do
  describe '.send_instructeur_email_notification' do
    let(:procedure) { create(:procedure, :published) }
    let(:groupe_instructeur) { create(:groupe_instructeur, procedure:, instructeurs: [instructeur]) }
    let(:instructeur) { create(:instructeur) }

    before do
      allow(InstructeurMailer).to receive(:send_notifications)
        .and_return(double(deliver_later: true))
    end

    subject { NotificationService.send_instructeur_email_notification }

    context 'when a instructeur does not enable its email notification' do
      let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

      before { create(:instructeurs_procedure, instructeur: instructeur, procedure: procedure) }

      it do
        subject
        expect(InstructeurMailer).not_to have_received(:send_notifications)
      end
    end

    context 'when a instructeur enables its email_notification on one procedure' do
      before do
        create(:instructeurs_procedure,
          instructeur: instructeur,
          procedure: procedure,
          daily_email_summary: true)
      end

      context "when there is no activity on the instructeur's procedures" do
        it do
          subject
          expect(InstructeurMailer).not_to have_received(:send_notifications)
        end
      end

      context 'when a dossier en construction exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_construction, procedure:, groupe_instructeur:) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier en instruction exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_instruction, procedure:, groupe_instructeur:) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier accepte exists on this procedure' do
        let!(:dossier) { create(:dossier, :accepte, procedure:, groupe_instructeur:) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier refuse exists on this procedure' do
        let!(:dossier) { create(:dossier, :refuse, procedure:, groupe_instructeur:) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier classé sans suite exists on this procedure' do
        let!(:dossier) { create(:dossier, :sans_suite, procedure:, groupe_instructeur:) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when there is a notification on this procedure' do
        let(:dossier) { create(:dossier, :en_construction, procedure:, groupe_instructeur:) }
        let!(:notification) { create(:dossier_notification, instructeur: instructeur, dossier:, notification_type: :dossier_modifie) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end
    end
  end
end
