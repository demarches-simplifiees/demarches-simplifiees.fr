describe GroupeGestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:administrateurs) }
    it { is_expected.to have_and_belong_to_many(:gestionnaires) }
  end

  describe "#add_gestionnaire" do
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }
    let(:gestionnaire) { create(:gestionnaire) }

    subject { groupe_gestionnaire.add_gestionnaire(gestionnaire) }

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

  describe "#add_administrateur" do
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:administrateur) { create(:administrateur) }

    subject { groupe_gestionnaire.add_administrateur(administrateur) }

    it 'adds the administrateur to the groupe gestionnaire' do
      subject
      expect(groupe_gestionnaire.reload.administrateurs).to include(administrateur)
    end
  end

  describe "#add_administrateurs" do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
    let(:administrateur) { create(:administrateur) }

    it 'adds the administrateur by id' do
      groupe_gestionnaire.add_administrateurs(ids: [administrateur.id], current_user: gestionnaire)
      expect(groupe_gestionnaire.reload.administrateurs).to include(administrateur)
    end

    it 'adds the existing administrateur by email' do
      groupe_gestionnaire.add_administrateurs(emails: [administrateur.email], current_user: gestionnaire)
      expect(groupe_gestionnaire.reload.administrateurs).to include(administrateur)
    end

    context "when administrateurs_already_in_groupe_gestionnaire" do
      let(:other_groupe_gestionnaire) { create(:groupe_gestionnaire) }
      let(:administrateur) { create(:administrateur, groupe_gestionnaire_id: other_groupe_gestionnaire.id) }
      it 'does not add the existing administrateur by email' do
        groupe_gestionnaire.add_administrateurs(emails: [administrateur.email], current_user: gestionnaire)
        expect(groupe_gestionnaire.reload.administrateurs).not_to include(administrateur)
      end
    end

    it 'adds the new administrateur by email' do
      groupe_gestionnaire.add_administrateurs(emails: ['new_administrateur@ds.fr'], current_user: gestionnaire)
      expect(groupe_gestionnaire.reload.administrateurs.last.email).to eq('new_administrateur@ds.fr')
    end
  end

  describe "#remove_administrateur" do
    let(:gestionnaire) { create(:gestionnaire) }
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
    let!(:administrateur) { create(:administrateur, groupe_gestionnaire_id: groupe_gestionnaire.id) }

    it 'removes the administrateur by id' do
      expect(groupe_gestionnaire.reload.administrateurs.size).to eq(1)
      groupe_gestionnaire.remove_administrateur(administrateur.id, gestionnaire)
      expect(groupe_gestionnaire.reload.administrateurs).not_to include(administrateur)
      expect(groupe_gestionnaire.reload.administrateurs.size).to eq(0)
    end
  end
end
