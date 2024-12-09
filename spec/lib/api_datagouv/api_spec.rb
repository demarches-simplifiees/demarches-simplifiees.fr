# frozen_string_literal: true

describe APIDatagouv::API do
  describe '#upload' do
    let(:dataset) { '62a0afdacffa4c3ea5cbd1b4' }
    let(:resource) { '666211e9-6226-4fad-8d2f-5a4135f40e47' }
    let(:datagouv_secret) { Rails.application.secrets.datagouv }
    let(:subject) { APIDatagouv::API.upload(Tempfile.new, dataset, resource) }

    before do
      stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/1\/datasets\/#{dataset}\/resources\/#{resource}\/upload\//)
        .to_return(body: body, status: status)
    end

    context "when response ok" do
      let(:status) { 200 }
      let(:body) { "ok" }

      it 'returns body response' do
        expect(subject).to eq body
      end
    end

    context "when responds with error" do
      let(:status) { 400 }
      let(:body) { "oops ! There is a problem..." }

      it 'raise error' do
        expect { subject }.to raise_error(APIDatagouv::API::RequestFailed)
      end
    end
  end
end
