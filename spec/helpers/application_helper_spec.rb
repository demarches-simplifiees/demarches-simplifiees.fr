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

  describe "#ensure_safe_json" do
    subject { ensure_safe_json(json) }

    context "with a dirty json" do
      let(:json) { "alert('haha');" }
      it { is_expected.to eq({}) }
    end

    context 'with a correct json' do
      let(:json) { '[[{"lat": 2.0, "lng": 102.0}, {"lat": 3.0, "lng": 103.0}, {"lat": 2.0, "lng": 102.0}], [{"lat": 2.0, "lng": 102.0}, {"lat": 3.0, "lng": 103.0}, {"lat": 2.0, "lng": 102.0}]]' }
      it { is_expected.to eq("[[{\"lat\":2.0,\"lng\":102.0},{\"lat\":3.0,\"lng\":103.0},{\"lat\":2.0,\"lng\":102.0}],[{\"lat\":2.0,\"lng\":102.0},{\"lat\":3.0,\"lng\":103.0},{\"lat\":2.0,\"lng\":102.0}]]") }
    end
  end
end
