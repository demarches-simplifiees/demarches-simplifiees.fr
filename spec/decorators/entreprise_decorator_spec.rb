require 'spec_helper'

describe EntrepriseDecorator do
  let(:code_effectif) { '00' }
  let(:raison_sociale) { 'GRTGaz' }
  let(:nom) { 'mon nom' }
  let(:prenom) { 'mon prenom' }
  let(:entreprise_params) {
    {
      capital_social: 123_000,
      code_effectif_entreprise: code_effectif,
      raison_sociale: raison_sociale,
      nom: nom,
      prenom: prenom

    }
  }
  let(:entreprise) { create(:entreprise, entreprise_params) }
  subject { entreprise.decorate }
  describe '#raison_sociale_or_name' do
    subject { super().raison_sociale_or_name}
    context 'when raison_sociale exist' do
      let(:raison_sociale) { 'ma super raison_sociale' }
      it 'display raison_sociale' do
        expect(subject).to eq(raison_sociale)
      end
    end
    context 'when raison_sociale is nil' do
      let(:raison_sociale) { nil }
      it 'display nom and prenom' do
        expect(subject).to eq(nom + ' ' + prenom)
      end
    end
  end

  describe '#effectif' do
    subject { super().effectif }
    context 'when code_effectif is 00' do
      let(:code_effectif) { '01' }
      it { is_expected.to eq('1 ou 2 salariés') }
    end
    context 'when code_effectif is 32' do
      let(:code_effectif) { '32' }
      it { is_expected.to eq('250 à 499 salariés') }
    end
  end

  describe '#pretty_capital_social' do
    it 'pretty display capital_social' do
      expect(subject.pretty_capital_social).to eq('123 000.00 €')
    end
  end

  describe '#pretty_date_creation' do
    it 'pretty print date creation' do
      expect(subject.pretty_date_creation).to eq('05-11-2001')
    end
  end
end