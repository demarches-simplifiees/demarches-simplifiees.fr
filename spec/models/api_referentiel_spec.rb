# frozen_string_literal: true

require 'rails_helper'

describe Referentiels::APIReferentiel, type: :model do
  let(:authentication_data) { { "header" => 'Authorization', "value" => 'Bearer secret' } }
  it 'encrypts authentication_data' do
    referentiel = described_class.create!(name: SecureRandom.uuid, url: 'https://api.gouv.fr', authentication_data:)

    referentiel.reload
    expect(referentiel.authentication_data).to eq(authentication_data)
    expect(Referentiel.where(id: referentiel.id).pluck(:authentication_data)).not_to include("Authorization")
  end
end
