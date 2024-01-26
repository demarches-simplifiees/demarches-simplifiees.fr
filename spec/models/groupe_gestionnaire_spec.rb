describe GroupeGestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:groupe_gestionnaire).optional }
    it { is_expected.to have_many(:children) }
    it { is_expected.to have_many(:administrateurs) }
    it { is_expected.to have_and_belong_to_many(:gestionnaires) }
  end

  describe "#add" do
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }
    let(:gestionnaire) { create(:gestionnaire) }

    subject { groupe_gestionnaire.add(gestionnaire) }

    it 'adds the gestionnaire to the groupe gestionnaire' do
      subject
      expect(groupe_gestionnaire.reload.gestionnaires).to include(gestionnaire)
    end
  end

  describe "#add_gestionnaires" do
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }
    let(:gestionnaire) { create(:gestionnaire) }

    it 'adds the gestionnaire by id' do
      groupe_gestionnaire.add_gestionnaires(ids: [gestionnaire.id])
      expect(groupe_gestionnaire.reload.gestionnaires).to include(gestionnaire)
    end

    it 'adds the existing gestionnaire by email' do
      groupe_gestionnaire.add_gestionnaires(emails: [gestionnaire.email])
      expect(groupe_gestionnaire.reload.gestionnaires).to include(gestionnaire)
    end

    it 'adds the new gestionnaire by email' do
      groupe_gestionnaire.add_gestionnaires(emails: ['new_gestionnaire@ds.fr'])
      expect(groupe_gestionnaire.reload.gestionnaires.last.email).to eq('new_gestionnaire@ds.fr')
    end
  end
end
