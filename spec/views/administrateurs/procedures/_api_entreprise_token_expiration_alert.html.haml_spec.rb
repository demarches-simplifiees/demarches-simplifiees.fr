# frozen_string_literal: true

RSpec.describe 'administrateurs/procedures/_api_entreprise_token_expiration_alert', type: :view do
  let(:procedure) { create(:procedure, api_entreprise_token:) }

  subject { render 'administrateurs/procedures/api_entreprise_token_expiration_alert', procedure: procedure }

  context "when there is no token" do
    let(:api_entreprise_token) { nil }

    it "does not render anything" do
      subject
      expect(rendered).to be_empty
    end
  end

  context "when the token is expired" do
    let(:api_entreprise_token) { JWT.encode({ exp: 2.days.ago.to_i }, nil, "none") }

    it "should display an error" do
      subject

      expect(rendered).to have_content("Votre jeton API Entreprise est expiré")
    end
  end

  context "when the token is valid it should display the expiration date" do
    let(:expiration) { 2.days.from_now }
    let(:api_entreprise_token) { JWT.encode({ exp: expiration.to_i }, nil, "none") }

    it "should display an error" do
      subject

      expect(rendered).to have_content("Votre jeton API Entreprise expirera le\n#{expiration.strftime('%d/%m/%Y à %H:%M')}")
    end
  end
end
