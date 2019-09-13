describe IndividualSerializer do
  describe '#attributes' do
    let(:procedure) { create(:procedure) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:individual) { create(:individual, gender: 'M.', nom: 'nom', prenom: 'prenom', birthdate: Date.new(2001, 8, 27), dossier: dossier) }

    subject { IndividualSerializer.new(individual).serializable_hash }

    it { is_expected.to include(civilite: 'M.') }
    it { is_expected.to include(nom: 'NOM') }
    it { is_expected.to include(prenom: 'Prenom') }
    it { is_expected.not_to have_key(:date_naissance) }

    context 'when the procedure asks for a birthdate' do
      before { procedure.update(ask_birthday: true) }

      it { is_expected.to include(date_naissance: Date.new(2001, 8, 27)) }
    end
  end
end
