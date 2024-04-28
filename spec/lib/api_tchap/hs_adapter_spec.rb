# frozen_string_literal: true

describe APITchap::HsAdapter do
  let(:adapter) { described_class.new(email) }
  let(:email) { "louise@mjc.gouv.fr" }
  subject { adapter.to_hs }

  before do
    stub_request(:get, /https:\/\/matrix.agent.tchap.gouv.fr\/_matrix\/identity\/api\/v1\/info\?address=#{email}&medium=email/)
      .to_return(body: body, status: status)
  end

  context 'with normal body' do
    let(:body) { "{\"hs\": \"agent.educpop.gouv.fr\" }" }
    let(:status) { 200 }
    it 'returns hs' do
      subject
      expect(subject).to eq "agent.educpop.gouv.fr"
    end
  end
end
