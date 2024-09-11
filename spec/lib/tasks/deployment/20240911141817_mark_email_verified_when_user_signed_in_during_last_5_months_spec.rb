
# frozen_string_literal: true

describe 'after_party:mark_email_verified_when_user_signed_in_during_last_5_months' do
  let(:rake_task) { Rake::Task['after_party:mark_email_verified_when_user_signed_in_during_last_5_months'] }

  subject { rake_task.invoke }
  after(:each) { rake_task.reenable }

  let(:old_date) { 6.months.ago }

  let!(:user) { create(:user, email_verified_at: nil, sign_in_count: 1) }
  let!(:user2) { create(:user, email_verified_at: nil, sign_in_count: 1) }
  let!(:user3) { create(:user, email_verified_at: nil, sign_in_count: 0) }
  let!(:user4) { create(:user, email_verified_at: old_date, sign_in_count: 1) }

  it 'mark_email_verified_when_user_signed_in_during_last_5_months' do
    expect(User.where(email_verified_at: nil, sign_in_count: 1..).count).to eq(2)

    subject

    expect(User.where(email_verified_at: nil, sign_in_count: 1..).count).to eq(0)
    expect(user.reload.email_verified_at).to be_present
    expect(user2.reload.email_verified_at).to be_present
    expect(user3.reload.email_verified_at).to be_nil
    expect(user4.reload.email_verified_at.to_i).to eq(old_date.to_i)
  end
end
