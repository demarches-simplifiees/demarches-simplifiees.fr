require 'spec_helper'

describe QuartierPrioritaire do
  it { is_expected.to have_db_column(:code) }
  it { is_expected.to have_db_column(:nom) }
  it { is_expected.to have_db_column(:commune) }
  it { is_expected.to have_db_column(:geometry) }

  it { is_expected.to belong_to(:dossier) }
end
