require 'rspec'

describe 'root/_footer.html.haml', type: :view do
  describe 'contains Net.pf logo' do
    before do
      render
    end
    subject { rendered }
    it { is_expected.to have_css('.footer-logo-netpf') }
  end
end
