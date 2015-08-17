require 'spec_helper'

describe EvenementVie do
  describe 'database column' do
    it { is_expected.to have_db_column(:nom) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
    it { is_expected.to have_db_column(:use_admi_facile) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:formulaires) }
  end

  describe '.for_admi_facile' do
    let(:evenement_for_admi_facile) { EvenementVie.where(use_admi_facile: true).first }
    let(:evenement_not_for_admi_facile) { EvenementVie.where(use_admi_facile: false).first }
    subject { EvenementVie.for_admi_facile }
    it 'returns elements where use_admi_facile is true' do
      expect(subject).to include(evenement_for_admi_facile)
    end
    it 'does not return elements where use_admi_facile is false' do
      expect(subject).not_to include(evenement_not_for_admi_facile)
    end
  end
end