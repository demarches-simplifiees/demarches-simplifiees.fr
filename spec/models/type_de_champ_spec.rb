require 'spec_helper'

describe TypeDeChamp do
  describe 'database columns' do
    it { is_expected.to have_db_column(:libelle) }
    it { is_expected.to have_db_column(:type_champs) }
    it { is_expected.to have_db_column(:order_place) }
    it { is_expected.to have_db_column(:description) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:procedure) }
    it { is_expected.to have_many(:champ) }
  end

  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('Montant projet').for(:libelle) }
    end

    context 'type' do
      it { is_expected.not_to allow_value(nil).for(:type_champs) }
      it { is_expected.not_to allow_value('').for(:type_champs) }

      it { is_expected.to allow_value('text').for(:type_champs) }
      it { is_expected.to allow_value('textarea').for(:type_champs) }
      it { is_expected.to allow_value('datetime').for(:type_champs) }
      it { is_expected.to allow_value('number').for(:type_champs) }
    end

    context 'order_place' do
      it { is_expected.not_to allow_value(nil).for(:order_place) }
      it { is_expected.not_to allow_value('').for(:order_place) }
      it { is_expected.to allow_value(1).for(:order_place) }
    end

    context 'description' do
      it { is_expected.to allow_value(nil).for(:description) }
      it { is_expected.to allow_value('').for(:description) }
      it { is_expected.to allow_value('blabla').for(:description) }
    end
  end
end
