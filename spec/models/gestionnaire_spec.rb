describe Gestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to have_and_belong_to_many(:groupe_gestionnaires) }
  end
end
