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

      context 'when a declarative dossier in instruction exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
        before do
          procedure.update(declarative_with_state: "en_instruction")
          DeclarativeProceduresJob.new.perform
          dossier.reload
        end

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a declarative dossier in accepte on yesterday exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
        before do
          procedure.update(declarative_with_state: "accepte")
          DeclarativeProceduresJob.new.perform
          dossier.traitements.last.update!(processed_at: Time.zone.yesterday.beginning_of_day)
          dossier.reload
        end

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end

      context 'when a declarative dossier in accepte on today exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
        before do
          procedure.update(declarative_with_state: "accepte")
          DeclarativeProceduresJob.new.perform
          dossier.reload
        end

        it do
          subject
          expect(InstructeurMailer).not_to have_received(:send_notifications)
        end
      end

      context 'when there is a notification on this procedure' do
        before do
          allow_any_instance_of(Instructeur).to receive(:notifications_for_procedure)
            .and_return([12])
        end

        it do
          subject
          expect(InstructeurMailer).to have_received(:send_notifications)
        end
      end
    end
  end
end
