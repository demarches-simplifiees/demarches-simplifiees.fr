require 'spec_helper'

describe Cerfa do
  describe 'database columns' do
    it { is_expected.to have_db_column(:content)}
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
  end

end