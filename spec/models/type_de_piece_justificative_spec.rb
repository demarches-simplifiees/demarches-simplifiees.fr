require 'spec_helper'

describe TypeDePieceJustificative do
  describe 'database columns' do
    it { is_expected.to have_db_column(:libelle) }
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:api_entreprise) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:pieces_justificatives) }
    it { is_expected.to belong_to(:procedure) }
  end
end
