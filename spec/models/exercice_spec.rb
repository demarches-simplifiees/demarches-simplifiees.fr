require 'spec_helper'

describe Exercice do
  describe 'database columns' do
    it { is_expected.to have_db_column(:ca) }
    it { is_expected.to have_db_column(:dateFinExercice) }
    it { is_expected.to have_db_column(:date_fin_exercice_timestamp) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:etablissement) }
  end
end
