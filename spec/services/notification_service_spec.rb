describe NotificationService do
  describe '.send_gestionnaire_email_notification' do
    let(:procedure) { create(:procedure) }

    before do
      allow(GestionnaireMailer).to receive(:send_notifications)
        .and_return(double(deliver_later: true))
    end

    subject { NotificationService.send_gestionnaire_email_notification }

    context 'when a gestionnaire does not enable its email notification' do
      let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let(:gestionnaire) { create(:gestionnaire) }

      before { create(:assign_to, gestionnaire: gestionnaire, procedure: procedure) }

      it do
        subject
        expect(GestionnaireMailer).not_to have_received(:send_notifications)
      end
    end

    context 'when a gestionnaire enables its email_notification on one procedure' do
      let(:gestionnaire_with_email_notifications) { create(:gestionnaire) }

      before do
        create(:assign_to,
          gestionnaire: gestionnaire_with_email_notifications,
          procedure: procedure,
          email_notifications_enabled: true)
      end

      context "when there is no activity on the gestionnaire's procedures" do
        it do
          subject
          expect(GestionnaireMailer).not_to have_received(:send_notifications)
        end
      end

      context 'when a dossier en construction exists on this procedure' do
        let!(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

        it do
          subject
          expect(GestionnaireMailer).to have_received(:send_notifications)
        end
      end

      context 'when there is a notification on this procedure' do
        before do
          allow_any_instance_of(Gestionnaire).to receive(:notifications_for_procedure)
            .and_return([12])
        end

        it do
          subject
          expect(GestionnaireMailer).to have_received(:send_notifications)
        end
      end
    end
  end
end
