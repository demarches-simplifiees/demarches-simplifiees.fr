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
    let(:gestionnaire_to_add) { create(:gestionnaire) }

    it 'adds the gestionnaire by id' do
      groupe_gestionnaire.add_gestionnaires(ids: [gestionnaire_to_add.id], current_user: gestionnaire)
      expect(groupe_gestionnaire.reload.gestionnaires).to include(gestionnaire_to_add)
    end

    it 'adds the existing gestionnaire by email' do
      groupe_gestionnaire.add_gestionnaires(emails: [gestionnaire_to_add.email], current_user: gestionnaire)
      expect(groupe_gestionnaire.reload.gestionnaires).to include(gestionnaire_to_add)
    end

    it 'adds the new gestionnaire by email' do
      groupe_gestionnaire.add_gestionnaires(emails: ['new_gestionnaire@ds.fr'], current_user: gestionnaire)
      expect(groupe_gestionnaire.reload.gestionnaires.last.email).to eq('new_gestionnaire@ds.fr')
    end
  end

  describe "#remove" do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:gestionnaire_to_remove) { create(:gestionnaire) }
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire, gestionnaire_to_remove]) }

    it 'removes the gestionnaire by id' do
      expect(groupe_gestionnaire.reload.gestionnaires.size).to eq(2)
      groupe_gestionnaire.remove(gestionnaire_to_remove.id, gestionnaire)
      expect(groupe_gestionnaire.reload.gestionnaires).not_to include(gestionnaire_to_remove)
      expect(groupe_gestionnaire.reload.gestionnaires.size).to eq(1)
    end

    it 'does not remove the gestionnaire if last' do
      expect(groupe_gestionnaire.reload.gestionnaires.size).to eq(2)
      groupe_gestionnaire.remove(gestionnaire.id, gestionnaire)
      expect(groupe_gestionnaire.reload.gestionnaires.size).to eq(1)
      groupe_gestionnaire.remove(gestionnaire_to_remove.id, gestionnaire)
      expect(groupe_gestionnaire.reload.gestionnaires).to include(gestionnaire_to_remove)
      expect(groupe_gestionnaire.reload.gestionnaires.size).to eq(1)
    end
  end
end
