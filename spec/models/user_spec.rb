require 'rails_helper'

describe User, type: :model do
  describe 'database columns' do
    it { is_expected.to have_db_column(:email) }
    it { is_expected.to have_db_column(:encrypted_password) }
    it { is_expected.to have_db_column(:reset_password_token) }
    it { is_expected.to have_db_column(:reset_password_sent_at) }
    it { is_expected.to have_db_column(:remember_created_at) }
    it { is_expected.to have_db_column(:sign_in_count) }
    it { is_expected.to have_db_column(:current_sign_in_at) }
    it { is_expected.to have_db_column(:last_sign_in_at) }
    it { is_expected.to have_db_column(:current_sign_in_ip) }
    it { is_expected.to have_db_column(:last_sign_in_ip) }
    it { is_expected.to have_db_column(:created_at) }
    it { is_expected.to have_db_column(:updated_at) }
  end
  describe 'associations' do
    it { is_expected.to have_many(:dossiers) }
  end
end
