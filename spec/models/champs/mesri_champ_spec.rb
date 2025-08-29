# frozen_string_literal: true

describe Champs::MesriChamp, type: :model do
  let(:types_de_champ_public) { [{ type: :mesri }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }

  describe '#validate' do
    let(:validation_context) { :create }

    subject { champ.valid?(validation_context) }

    before do
      champ.ine = ine
    end

    context 'when INE is valid' do
      let(:ine) { '090601811AB' }

      it { is_expected.to be true }
    end

    context 'when INE is nil' do
      let(:ine) { nil }

      it { is_expected.to be true }
    end
  end
end
