require 'spec_helper'

describe Champs do
  describe 'database columns' do
    it { is_expected.to have_db_column(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:type_de_champs) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:libelle).to(:type_de_champs) }
    it { is_expected.to delegate_method(:type_champs).to(:type_de_champs) }
    it { is_expected.to delegate_method(:order_place).to(:type_de_champs) }
  end
end