require 'spec_helper'

describe RNAInformation do
  describe 'databse columns' do
    it { is_expected.to have_db_column(:association_id) }
    it { is_expected.to have_db_column(:titre) }
    it { is_expected.to have_db_column(:objet) }
    it { is_expected.to have_db_column(:date_creation) }
    it { is_expected.to have_db_column(:date_publication) }
    it { is_expected.to have_db_column(:date_declaration) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:entreprise) }
  end
end
