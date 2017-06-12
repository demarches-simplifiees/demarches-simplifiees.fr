require 'spec_helper'

describe PrevisualisationService do
  describe '.destroy_all_champs' do
    subject { described_class.destroy_all_champs dossier }

    let(:procedure_1) { create :procedure, :with_type_de_champ }
    let(:procedure_2) { create :procedure, :with_type_de_champ }

    let!(:dossier_1) { create :dossier, procedure: procedure_1 }
    let!(:dossier_2) { create :dossier, procedure: procedure_2 }

    it { expect(Dossier.all.size).to eq 2 }
    it { expect(TypeDeChamp.all.size).to eq 2 }
    it { expect(Champ.all.size).to eq 2 }

    context 'when function destroy_all_champs is call' do
      let(:dossier) { dossier_1 }

      before do
        subject
      end

      it { expect(Dossier.all.size).to eq 2 }
      it { expect(TypeDeChamp.all.size).to eq 2 }
      it { expect(Champ.all.size).to eq 1 }
      it { expect(Champ.first.type_de_champ).to eq procedure_2.types_de_champ.first }
    end
  end
end
