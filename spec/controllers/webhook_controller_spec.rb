describe WebhookController, type: :controller do
  before do
    allow(controller).to receive(:verify_helpscout_signature!).and_return(true)
    allow(controller).to receive(:verify_authenticity_token)
  end

  describe '#helpscout_support_dev' do
    subject(:response) { post :helpscout_support_dev, params: payload }
    let(:payload) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'files', 'helpscout', 'tagged-dev.json'))) }
    let(:webhook_url) { "https://notification_url" }
    it 'works' do
      allow(Rails.application.secrets).to receive(:dig).with(:mattermost, :support_webhook_url).and_return(webhook_url)
      expect(controller).to receive(:send_mattermost_notification).with(webhook_url, "\nNouveau bug taggué #dev : https://secure.helpscout.net/conversation/123456789/123456789?folderId=123456789\n\n> Bonjour,    Je voudrais faire une demande de changement d'adresse et la plateforme m'indique que j'ai plusieurs comptes et que je dois d'abord les fusionner.    Cela fait 3 jours que j'essaie de fusio\n\n**personnes impliquées** : anonymous@anon.fr\n**utilisateur en attente depuis** : 11 min ago")
      subject
    end
  end

  describe '#helpscout' do
    subject(:response) { get :helpscout, params: { customer: { email: customer_email } } }

    let(:payload) { JSON.parse(subject.body) }
    let(:customer_email) { 'a-user@exemple.fr' }

    it "doesn't verify authenticity token" do
      subject
      expect(controller).not_to have_received(:verify_authenticity_token)
    end

    context 'when there is no matching user' do
      let(:customer_email) { 'not-a-user@exemple.fr' }

      it 'returns an empty response' do
        expect(subject.status).to eq(404)
        expect(subject.body).to be_empty
      end
    end

    context 'when there is a matching user' do
      let(:user) { create(:user, :with_strong_password) }
      let(:customer_email) { user.email }

      it 'returns a 200 response' do
        expect(subject.status).to eq(200)
        expect(subject.body).to be_present
      end

      it 'returns a link to the User profile in the Manager' do
        expect(payload).to have_key('html')
        expect(payload['html']).to have_selector("a[href='#{manager_user_url(user)}']")
      end

      context 'when there are an associated Instructeur and Administrateur' do
        let!(:instructeur) { create(:instructeur,    user: user) }
        let!(:admin)       { create(:administrateur, user: user, instructeur: instructeur) }

        it 'returns a link to the Instructeur profile in the Manager' do
          expect(payload).to have_key('html')
          expect(payload['html']).to have_selector("a[href='#{manager_instructeur_url(instructeur)}']")
        end

        it 'returns a link to the Administrateur profile in the Manager' do
          expect(payload).to have_key('html')
          expect(payload['html']).to have_selector("a[href='#{manager_administrateur_url(admin)}']")
        end
      end
    end
  end

  describe '#sendinblue' do
    subject(:response) { post :sendinblue, params: payload }
    let(:payload) { JSON.parse(File.read(Rails.root.join('spec', 'fixtures', 'files', 'sendinblue', 'incident.json'))) }

    it 'sends notification to mattermost' do
      notification_url = "https://notification_url"
      allow(Rails.application.secrets).to receive(:dig).with(:mattermost, :send_in_blue_outage_webhook_url).and_return(notification_url)
      expect(controller).to receive(:send_mattermost_notification).with(notification_url, "Incident sur SIB : Database Issues.\nEtat de SIB: Degraded Performance\nL'Incident a commencé à 2015-04-03T18:27:15+00:00 et est p-e terminé a \nles composant suivants sont affectés : Chat Service, Voice Services, Admin Dashboard")
      subject
    end
  end
end
