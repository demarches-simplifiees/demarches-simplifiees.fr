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
end
