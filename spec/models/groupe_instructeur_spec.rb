require 'spec_helper'

describe GroupeInstructeur, type: :model do
  let(:procedure) { create(:procedure) }
  subject { GroupeInstructeur.new(label: label, procedure: procedure) }

  context 'with no label provided' do
    let(:label) { '' }

    it { is_expected.to be_invalid }
  end

  context 'with a valid label' do
    let(:label) { 'Préfecture de la Marne' }

    it { is_expected.to be_valid }
  end

  context 'with a label with extra spaces' do
    let(:label) { 'Préfecture de la Marne      ' }
    before do
      subject.save
      subject.reload
    end

    it { is_expected.to be_valid }
    it { expect(subject.label).to eq("Préfecture de la Marne") }
  end

  context 'with a label already used for this procedure' do
    let(:label) { 'Préfecture de la Marne' }
    before do
      GroupeInstructeur.create!(label: label, procedure: procedure)
    end

    it { is_expected.to be_invalid }
  end
end
