require 'spec_helper'

describe TypeDePieceJustificative do
  let!(:procedure) { create(:procedure) }

  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('RIB').for(:libelle) }
    end

    context 'order_place' do
      # it { is_expected.not_to allow_value(nil).for(:order_place) }
      # it { is_expected.not_to allow_value('').for(:order_place) }
      it { is_expected.to allow_value(1).for(:order_place) }
    end

    context 'lien_demarche' do
      it { is_expected.to allow_value(nil).for(:lien_demarche) }
      it { is_expected.to allow_value('').for(:lien_demarche) }
      it { is_expected.not_to allow_value('not-a-link').for(:lien_demarche) }
      it { is_expected.to allow_value('http://link').for(:lien_demarche) }
    end
  end
end
