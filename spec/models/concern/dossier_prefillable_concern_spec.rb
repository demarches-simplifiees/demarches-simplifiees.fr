# frozen_string_literal: true

RSpec.describe DossierPrefillableConcern do
  describe '.prefill!' do
    let(:procedure) { create(:procedure, :published) }
    let(:dossier) { create(:dossier, :brouillon, procedure: procedure) }

    subject(:fill) { dossier.prefill!(values) }

    context 'when champs_public_attributes is empty' do
      let(:values) { [] }

      it "does nothing" do
        expect(dossier).not_to receive(:save)
        fill
      end
    end

    context 'when champs_public_attributes has values' do
      context 'when the champs are valid' do
        let!(:type_de_champ_1) { create(:type_de_champ_text, procedure: procedure) }
        let(:value_1) { "any value" }
        let(:champ_id_1) { dossier.find_champ_by_stable_id(type_de_champ_1.stable_id).id }

        let!(:type_de_champ_2) { create(:type_de_champ_phone, procedure: procedure) }
        let(:value_2) { "33612345678" }
        let(:champ_id_2) { dossier.find_champ_by_stable_id(type_de_champ_2.stable_id).id }

        let(:values) { [{ id: champ_id_1, value: value_1 }, { id: champ_id_2, value: value_2 }] }

        it "updates the champs with the new values" do
          fill
          expect(dossier.champs_public.first.value).to eq(value_1)
          expect(dossier.champs_public.last.value).to eq(value_2)
        end
      end

      context 'when a champ is invalid' do
        let!(:type_de_champ) { create(:type_de_champ_phone, procedure: procedure) }
        let(:value) { "a non phone value" }
        let(:champ_id) { dossier.find_champ_by_stable_id(type_de_champ.stable_id).id }

        let(:values) { [{ id: champ_id, value: value }] }

        it "still updates the champ" do
          expect { fill }.to change { dossier.champs_public.first.value }.from(nil).to(value)
        end
      end
    end
  end
end
