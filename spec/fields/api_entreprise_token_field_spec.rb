# frozen_string_literal: true

describe APIEntrepriseTokenField do
  subject(:api_entreprise_token_field) { described_class.new(:api_entreprise_token, token, :show) }
  let(:token) { APIEntrepriseToken.new(jwt_token) }

  describe "#to_s" do
    context "when there is no token data" do
      let(:jwt_token) { nil }

      it "returns 'Pas de token'" do
        expect(api_entreprise_token_field.to_s).to eq("Pas de token")
      end
    end

    context "when the token is valid and has no expiration" do
      let(:jwt_token) { JWT.encode({}, nil, 'none') }

      it "returns a message indicating the token is present without expiration" do
        expect(api_entreprise_token_field.to_s).to eq("Token présent, sans expiration")
      end
    end

    context "when the token is valid and has a future expiration date" do
      let(:expiration_time) { 2.days.from_now.to_i }
      let(:jwt_token) { JWT.encode({ 'exp' => expiration_time }, nil, 'none') }

      it "returns a message indicating the token will expire in the future" do
        expected_message = "Token présent, expirera le #{Time.zone.at(expiration_time).strftime('%d/%m/%Y à %H:%M')}"
        expect(api_entreprise_token_field.to_s).to eq(expected_message)
      end
    end

    context "when the token is valid and has a past expiration date" do
      let(:expiration_time) { 2.days.ago.to_i }
      let(:jwt_token) { JWT.encode({ 'exp' => expiration_time }, nil, 'none') }

      it "returns a message indicating the token has expired" do
        expected_message = "Token présent, expiré le #{Time.zone.at(expiration_time).strftime('%d/%m/%Y à %H:%M')}"
        expect(api_entreprise_token_field.to_s).to eq(expected_message)
      end
    end
  end
end
