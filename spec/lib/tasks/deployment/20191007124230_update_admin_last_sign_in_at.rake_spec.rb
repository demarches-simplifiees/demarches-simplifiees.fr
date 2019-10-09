describe '20191007124230_update_admin_last_sign_in_at.rake' do
  let(:rake_task) { Rake::Task['after_party:update_admin_last_sign_in_at'] }

  subject { rake_task.invoke }
  after { rake_task.reenable }

  context 'with 2 administrateurs' do
    let!(:admin) { create(:administrateur, active: true) }
    let(:user) { admin.user }
    let!(:admin2) { create(:administrateur, active: false) }
    let(:user2) { admin2.user }

    before do
    end

    it do
      expect(admin.active).to be true
      expect(user.last_sign_in_at).to be_nil
      expect(admin.updated_at).not_to be_nil

      subject

      expect(user.reload.last_sign_in_at).to eq(admin.reload.updated_at)
      expect(user2.reload.last_sign_in_at).to be_nil
    end
  end
end
