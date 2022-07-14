describe APIDatagouv::API do
  describe '#upload' do
    let(:subject) { APIDatagouv::API.upload(Tempfile.new.path) }

    before do
      stub_request(:post, /https:\/\/www.data.gouv.fr\/api/)
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
