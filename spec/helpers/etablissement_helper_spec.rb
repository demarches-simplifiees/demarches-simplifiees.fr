RSpec.describe EtablissementHelper, type: :helper do
  let(:code_effectif) { '00' }
  let(:raison_sociale) { 'GRTGaz' }
  let(:nom) { 'mon nom' }
  let(:prenom) { 'mon prenom' }
  let(:entreprise_params) do
    {
      entreprise_capital_social: 123_000,
      entreprise_code_effectif_entreprise: code_effectif,
      entreprise_raison_sociale: raison_sociale,
      entreprise_nom: nom,
      entreprise_prenom: prenom
    }
  end
  let(:etablissement) { create(:etablissement, entreprise_params) }

  describe '#raison_sociale_or_name' do
    subject { raison_sociale_or_name(etablissement) }

    context 'when raison_sociale exist' do
      let(:raison_sociale) { 'ma super raison_sociale' }
      it 'display raison_sociale' do
        expect(subject).to eq(raison_sociale)
      end
    end

    context 'when raison_sociale is nil' do
      let(:raison_sociale) { nil }
      it 'display nom and prenom' do
        expect(subject).to eq("#{nom} #{prenom}")
      end
    end
  end

  describe '#effectif' do
    subject { effectif(etablissement) }

    context 'when code_effectif is 00' do
      let(:code_effectif) { '01' }
      it { is_expected.to eq('1 ou 2 salariés') }
    end

    context 'when code_effectif is 32' do
      let(:code_effectif) { '32' }
      it { is_expected.to eq('250 à 499 salariés') }
    end

    context 'when code effectif is polynesian code 6' do
      let(:code_effectif) { '8' }
      it { is_expected.to eq('200 à 499 personnes') }
    end
  end

  describe '#pretty_currency' do
    subject { pretty_currency(etablissement.entreprise_capital_social) }

    it { is_expected.to eq('123 000,00 €') }
  end
end
