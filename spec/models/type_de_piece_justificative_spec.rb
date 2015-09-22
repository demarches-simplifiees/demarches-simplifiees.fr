require 'spec_helper'

describe TypeDePieceJustificative do
  let!(:procedure) { create(:procedure) }

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

  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('RIB').for(:libelle) }
    end

    context 'description' do
      it { is_expected.not_to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value('').for(:description) }
      it { is_expected.to allow_value('Releve identité bancaire').for(:description) }
    end
  end
end
