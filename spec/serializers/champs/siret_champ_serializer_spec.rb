describe Champs::SiretChampSerializer do
  describe '#attributes' do
    subject { Champs::SiretChampSerializer.new(champ).serializable_hash }

    context 'when type champ is siret' do
      let(:etablissement) { create(:etablissement) }
      let(:champ) { create(:type_de_champ_siret).champ.create(etablissement: etablissement, value: etablissement.siret) }

      it {
        is_expected.to include(value: etablissement.siret)
        expect(subject[:etablissement]).to include(siret: etablissement.siret)
        expect(subject[:entreprise]).to include(capital_social: etablissement.entreprise_capital_social)
      }
    end
  end
end
