# frozen_string_literal: true

describe APIEntrepriseTokenConcern do
  describe "#api_entreprise_token_expired_or_expires_soon?" do
    subject { procedure.api_entreprise_token_expired_or_expires_soon? }

    let(:procedure) { create(:procedure, api_entreprise_token:) }

    context "when there is no token" do
      let(:api_entreprise_token) { nil }

      it { is_expected.to be_falsey }
    end

    context "when the token expires in 2 months" do
      let(:api_entreprise_token) { JWT.encode({ exp: 2.months.from_now.to_i }, nil, "none") }

      it { is_expected.to be_falsey }
    end

    context "when the token expires tomorrow" do
      let(:api_entreprise_token) { JWT.encode({ exp: 1.day.from_now.to_i }, nil, "none") }

      it { is_expected.to be_truthy }
    end

    context "when the token is expired" do
      let(:api_entreprise_token) { JWT.encode({ exp: 1.day.ago.to_i }, nil, "none") }

      it { is_expected.to be_truthy }
    end
  end
end
