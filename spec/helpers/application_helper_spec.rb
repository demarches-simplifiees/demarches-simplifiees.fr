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

  describe "#try_format_date" do
    subject { try_format_date(date) }

    describe 'try formatting a date' do
      let(:date) { Date.new(2019, 01, 24) }
      it { is_expected.to eq("24 janvier 2019") }
    end

    describe 'try formatting a blank string' do
      let(:date) { "" }
      it { is_expected.to eq("") }
    end

    describe 'try formatting a nil string' do
      let(:date) { nil }
      it { is_expected.to eq("") }
    end
  end

  describe "#try_format_datetime" do
    subject { try_format_datetime(datetime) }

    describe 'try formatting 31/01/2019 11:25' do
      let(:datetime) { Time.zone.local(2019, 01, 31, 11, 25, 00) }
      it { is_expected.to eq("31 janvier 2019 11:25") }
    end

    describe 'try formatting a blank string' do
      let(:datetime) { "" }
      it { is_expected.to eq("") }
    end

    describe 'try formatting a nil string' do
      let(:datetime) { nil }
      it { is_expected.to eq("") }
    end
  end
end
