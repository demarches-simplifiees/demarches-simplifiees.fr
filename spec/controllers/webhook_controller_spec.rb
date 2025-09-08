# frozen_string_literal: true

describe WebhookController, type: :controller do
  describe '#helpscout_support_dev' do
    before do
      allow(controller).to receive(:verify_helpscout_signature!).and_return(true)
      allow(controller).to receive(:verify_authenticity_token)
    end

    subject(:response) { post :helpscout_support_dev, params: payload }
    let(:payload) { JSON.parse(Rails.root.join('spec', 'fixtures', 'files', 'helpscout', 'tagged-dev.json').read) }
    let(:webhook_url) { "https://notification_url" }
    it 'works' do
      stub_const("ENV", ENV.to_hash.merge("SUPPORT_WEBHOOK_URL" => webhook_url))
      expect(controller).to receive(:send_mattermost_notification).with(webhook_url, "\nNouveau bug taggué #dev : https://secure.helpscout.net/conversation/123456789/123456789?folderId=123456789\n\n> Bonjour,    Je voudrais faire une demande de changement d'adresse et la plateforme m'indique que j'ai plusieurs comptes et que je dois d'abord les fusionner.    Cela fait 3 jours que j'essaie de fusio\n\n**personnes impliquées** : anonymous@anon.fr\n**utilisateur en attente depuis** : 11 min ago")
      subject
    end
  end

  describe '#helpscout' do
    before do
      allow(controller).to receive(:verify_helpscout_signature!).and_return(true)
      allow(controller).to receive(:verify_authenticity_token)
    end

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
          expect(payload['html']).to have_text("Notifications activées")
        end
      end

      context "when notifications are disabled" do
        let(:instructeur) { create(:instructeur, user:) }
        let(:procedure) { create(:procedure) }
        before do
          create(:assign_to, instructeur:, procedure:,
            instant_email_dossier_notifications_enabled: false)
        end

        it 'returns a summary of disabled notifications' do
          expect(payload['html']).to have_text("Notifs désactivées Procedure##{procedure.id}")
        end
      end
    end
  end

  describe '#sendinblue' do
    subject(:response) { post :sendinblue, params: payload }
    let(:payload) { JSON.parse(Rails.root.join('spec', 'fixtures', 'files', 'sendinblue', 'incident.json').read) }

    it 'sends notification to mattermost' do
      notification_url = "https://notification_url"
      stub_const('ENV', ENV.to_hash.merge('SEND_IN_BLUE_OUTAGE_WEBHOOK_URL' => notification_url))
      expect(controller).to receive(:send_mattermost_notification).with(notification_url, "Incident sur SIB : Database Issues.\nEtat de SIB: Degraded Performance\nL'Incident a commencé à 2015-04-03T18:27:15+00:00 et est p-e terminé a \nles composant suivants sont affectés : Chat Service, Voice Services, Admin Dashboard")
      subject
    end
  end

  describe '#crisp' do
    let(:payload) do
      {
        "event" => "message:send",
        "data" => {
          "from" => "user",
          "user" => { "user_id" => "default_user@user.com" }
        }
      }
    end

    let(:body) { payload }
    let(:timestamp) { Time.current }

    before do
      stub_const('ENV', ENV.to_hash.merge('CRISP_WEBHOOK_SECRET' => 'testsecret'))
    end

    it 'processes the webhook when signature is valid' do
      expected_signature = OpenSSL::HMAC.hexdigest('sha256',
        'testsecret',
        "[#{timestamp};#{body.to_json}]")

      expect(Crisp::WebhookProcessor).to receive(:new).and_call_original

      request.headers.merge!({
        'X-Crisp-Request-Timestamp' => timestamp,
        'X-Crisp-Signature' => expected_signature
      })

      post :crisp, params: body, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "doesn't process the webhook when signature is invalid" do
      expect(Crisp::WebhookProcessor).not_to receive(:new)

      request.headers.merge!({
        'X-Crisp-Request-Timestamp' => timestamp,
        'X-Crisp-Signature' => 'bad_signature'
      })

      post :crisp, params: body, as: :json
      expect(response).not_to have_http_status(:ok)
    end
  end
end
