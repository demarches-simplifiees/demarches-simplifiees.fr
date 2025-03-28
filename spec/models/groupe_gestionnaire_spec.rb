describe GroupeGestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:administrateurs) }
    it { is_expected.to have_many(:commentaire_groupe_gestionnaires) }
    it { is_expected.to have_many(:follow_commentaire_groupe_gestionnaires) }
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

  describe "#add_administrateur" do
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire) }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:administrateur) { administrateurs(:default_admin) }

    subject { groupe_gestionnaire.add_administrateur(administrateur) }

    it 'adds the administrateur to the groupe gestionnaire' do
      subject
      expect(groupe_gestionnaire.reload.administrateurs).to include(administrateur)
    end
  end
end
