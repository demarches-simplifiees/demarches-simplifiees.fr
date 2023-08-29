describe GroupeGestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:groupe_gestionnaire).optional }
    it { is_expected.to have_many(:children) }
    it { is_expected.to have_many(:administrateurs) }
    it { is_expected.to have_and_belong_to_many(:gestionnaires) }
  end
end
