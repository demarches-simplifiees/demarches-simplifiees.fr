describe IndividualSerializer do
  describe '#attributes' do
    let(:individual){ Individual.create(nom: 'nom', prenom: 'prenom') }

    subject { IndividualSerializer.new(individual).serializable_hash }

    it { is_expected.to include(nom: 'nom') }
    it { is_expected.to include(prenom: 'prenom') }
  end
end
