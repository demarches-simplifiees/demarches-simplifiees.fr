describe ApplicationHelper do
  describe "#sanitize_url" do
    subject { sanitize_url(url) }

    describe 'does nothing on clean url' do
      let(:url) { "https://tps.fr/toto" }
      it { is_expected.to eq(url) }
    end

    describe 'clean a dangerous url' do
      let(:url) { "javascript:alert('coucou jtai hacké')" }
      it { is_expected.to eq(root_url) }
    end

    describe 'can deal with a nil url' do
      let(:url) { nil }
      it { is_expected.to be_nil }
    end
  end
end
