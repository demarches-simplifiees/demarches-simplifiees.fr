require 'spec_helper'

describe Champ do
  describe 'database columns' do
    it { is_expected.to have_db_column(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:type_de_champ) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:libelle).to(:type_de_champ) }
    it { is_expected.to delegate_method(:type_champ).to(:type_de_champ) }
    it { is_expected.to delegate_method(:order_place).to(:type_de_champ) }
  end
end