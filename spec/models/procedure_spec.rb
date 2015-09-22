require 'spec_helper'

describe Procedure do
  describe 'assocations' do
    it { is_expected.to have_many(:types_de_piece_justificative) }
    it { is_expected.to have_many(:dossiers) }
  end

  describe 'attributes' do
    it { is_expected.to have_db_column(:libelle) }
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:organisation) }
    it { is_expected.to have_db_column(:direction) }
    it { is_expected.to have_db_column(:test) }
  end

  describe 'validation' do
    context 'libelle' do
      it { is_expected.not_to allow_value(nil).for(:libelle) }
      it { is_expected.not_to allow_value('').for(:libelle) }
      it { is_expected.to allow_value('Demande de subvention').for(:libelle) }
    end

    context 'description' do
      it { is_expected.not_to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value('').for(:description) }
      it { is_expected.to allow_value('Description Demande de subvention').for(:description) }
    end

    context 'lien_demarche' do
      it { is_expected.not_to allow_value(nil).for(:lien_demarche) }
      it { is_expected.not_to allow_value('').for(:lien_demarche) }
      it { is_expected.to allow_value('http://localhost').for(:lien_demarche) }
    end
  end
end
