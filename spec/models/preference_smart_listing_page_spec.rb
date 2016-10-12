require 'spec_helper'

describe PreferenceSmartListingPage do
  it { is_expected.to have_db_column(:page) }
  it { is_expected.to have_db_column(:liste) }
  it { is_expected.to have_db_column(:procedure_id) }

  it { is_expected.to belong_to(:gestionnaire) }
  it { is_expected.to belong_to(:procedure) }
end
