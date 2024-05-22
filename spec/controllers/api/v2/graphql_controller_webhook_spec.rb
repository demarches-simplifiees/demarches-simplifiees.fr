describe API::V2::GraphqlController do
  let(:admin) { create(:administrateur) }
  let(:token) { APIToken.generate(admin).second }
  let(:procedure) { create(:procedure, :published, :for_individual, :with_service, administrateurs: [admin]) }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }
  let(:webhook) { create(:webhook, procedure:) }

  let(:variables) { {} }
  let(:operation_name) { nil }
  let(:body) { subject }
  let(:gql_data) { body[:data] }
  let(:gql_errors) { body[:errors] }

  def execute_graphql(variables: nil, operation_name: nil)
    response = post :execute, params: { queryId: 'ds-webhook-v2', variables: variables, operationName: operation_name }.compact, as: :json
    JSON.parse(response.body, symbolize_names: true)
  end

  subject { execute_graphql(variables:, operation_name:) }

  before do
    request.env['HTTP_AUTHORIZATION'] = authorization_header
  end

  describe 'webhookCreate' do
    describe 'create' do
      let(:variables) do
        {
          input: {
            demarche: { number: procedure.id },
            label: 'My webhook',
            url: 'https://test.test/test',
            eventType: [:dossier_depose]
          }
        }
      end
      let(:operation_name) { 'webhookCreate' }

      it {
        expect { subject }.to change { Webhook.count }.by(1)
        expect(gql_data[:webhookCreate][:webhook][:label]).to eq('My webhook')
      }
    end
  end

  describe 'webhookUpdate' do
    let(:variables) do
      {
        input: {
          webhookId: webhook.to_typed_id,
          label: 'My new webhook'
        }
      }
    end
    let(:operation_name) { 'webhookUpdate' }

    it {
      expect(gql_errors).to be_nil
      expect(gql_data[:webhookUpdate][:webhook][:label]).to eq('My new webhook')
    }
  end

  describe 'webhookDelete' do
    let(:variables) do
      {
        input: {
          webhookId: webhook.to_typed_id
        }
      }
    end
    let(:operation_name) { 'webhookDelete' }

    it {
      webhook
      expect { subject }.to change { Webhook.count }.by(-1)
      expect(gql_data[:webhookDelete][:webhook][:label]).to eq('My webhook')
    }
  end
end
