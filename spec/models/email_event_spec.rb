RSpec.describe EmailEvent, type: :model do
  describe "#pseudonymize_email" do
    it { expect(EmailEvent.pseudonymize_email("example@rspec.com")).to eq("ex****e@rspec.com") }
    it { expect(EmailEvent.pseudonymize_email("exa@rspec.com")).to eq("***@rspec.com") }
    it { expect(EmailEvent.pseudonymize_email("e@rspec.com")).to eq("*@rspec.com") }
  end
end
