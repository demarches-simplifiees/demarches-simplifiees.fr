require 'spec_helper'

describe Notification do
  it { is_expected.to have_db_column(:already_read) }
  it { is_expected.to have_db_column(:liste) }
  it { is_expected.to have_db_column(:type_notif) }
  it { is_expected.to have_db_column(:created_at) }
  it { is_expected.to have_db_column(:updated_at) }

  it { is_expected.to belong_to(:dossier) }
end
