require 'spec_helper'

describe ModuleAPICarto do
  describe 'assocations' do
    it { is_expected.to belong_to(:procedure) }
  end

  describe 'attributes' do
    it { is_expected.to have_db_column(:use_api_carto) }
    it { is_expected.to have_db_column(:quartiers_prioritaires) }
    it { is_expected.to have_db_column(:cadastre) }
  end
end
