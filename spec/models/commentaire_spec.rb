require 'spec_helper'

describe Commentaire do
  it { is_expected.to have_db_column(:email) }
  it { is_expected.to have_db_column(:body) }
  it { is_expected.to have_db_column(:created_at) }
  it { is_expected.to have_db_column(:updated_at) }
  it { is_expected.to belong_to(:dossier) }
end