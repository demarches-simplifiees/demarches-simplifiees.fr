describe AdminsGroup, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:admins_group).optional }
    it { is_expected.to have_many(:children) }
    it { is_expected.to have_many(:administrateurs) }
    it { is_expected.to have_and_belong_to_many(:admins_group_managers) }
  end
end
