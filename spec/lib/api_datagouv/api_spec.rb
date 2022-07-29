describe APIDatagouv::API do
  describe '#upload' do
    let(:dataset) { :descriptif_demarches_dataset }
    let(:resource) { :descriptif_demarches_resource }
    let(:datagouv_secret) { Rails.application.secrets.datagouv }
    let(:subject) { APIDatagouv::API.upload(Tempfile.new, dataset, resource) }

    before do
      stub_request(:post, /https:\/\/www.data.gouv.fr\/api\/1\/datasets\/#{datagouv_secret[dataset]}\/resources\/#{datagouv_secret[resource]}\/upload\//)
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
