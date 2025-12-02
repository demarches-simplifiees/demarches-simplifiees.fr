# frozen_string_literal: true

describe NotificationService do
  describe '.send_instructeur_email_notification' do
    let(:procedure) { create(:procedure) }

    before do
      allow(InstructeurMailer).to receive(:send_notifications)
        .and_return(double(deliver_later: true))
    end

    subject { NotificationService.send_instructeur_email_notification }

    context 'when a instructeur does not enable its email notification' do
      let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let(:instructeur) { create(:instructeur) }

      before { create(:assign_to, instructeur: instructeur, procedure: procedure) }

      it do
        subject
        expect(InstructeurMailer).not_to have_received(:send_notifications)
      end
    end

    context 'when a instructeur enables its email_notification on one procedure' do
      let(:instructeur_with_email_notifications) { create(:instructeur) }

      before do
        create(:assign_to,
          instructeur: instructeur_with_email_notifications,
          procedure: procedure,
          daily_email_notifications_enabled: true)
      end

      context "when there is no activity on the instructeur's procedures" do
        it do
          subject
          expect(InstructeurMailer).not_to have_received(:send_notifications)
        end
      end

      context 'when a dossier en construction exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier en instruction exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier accepte exists on this procedure' do
        let!(:dossier) { create(:dossier, :accepte, procedure: procedure) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier refuse exists on this procedure' do
        let!(:dossier) { create(:dossier, :refuse, procedure: procedure) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a dossier classé sans suite exists on this procedure' do
        let!(:dossier) { create(:dossier, :sans_suite, procedure: procedure) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when there is a notification on this procedure' do
        let(:dossier) { create(:dossier, :en_construction, procedure:) }
        let!(:notification) { create(:dossier_notification, instructeur: instructeur_with_email_notifications, dossier:, notification_type: :dossier_modifie) }

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end
    end
  end
end
