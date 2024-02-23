describe ApplicationHelper do
  describe 'app_host_legacy?' do
    let(:request) { instance_double(ActionDispatch::Request, base_url: request_base_url) }
    let(:app_host_legacy) { 'legacy' }
    let(:app_host) { 'host' }

    before do
      stub_const("ApplicationHelper::APP_HOST_LEGACY", app_host_legacy)
      stub_const("ApplicationHelper::APP_HOST", app_host)
    end

    subject { app_host_legacy?(request) }

    context 'request on ENV[APP_HOST_LEGACY]' do
      let(:request_base_url) { app_host_legacy }
      it { is_expected.to be_truthy }
    end

    context 'request on ENV[APP_HOST]' do
      let(:request_base_url) { app_host }
      it { is_expected.to be_falsey }
    end
  end

  describe "#flash_class" do
    it { expect(flash_class('notice')).to eq 'alert-success' }
    it { expect(flash_class('alert', sticky: true, fixed: true)).to eq 'alert-danger sticky alert-fixed' }
    it { expect(flash_class('error')).to eq 'alert-danger' }
    it { expect(flash_class('unknown-level')).to eq '' }
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
