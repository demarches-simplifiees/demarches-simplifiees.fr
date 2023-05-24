# frozen_string_literal: true

RSpec.describe DossierPrefillableConcern do
  describe '.prefill!' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
    let(:dossier) { create(:dossier, :brouillon, procedure: procedure) }
    let(:types_de_champ_public) { [] }

    subject(:fill) { dossier.prefill!(values); dossier.reload }

    context 'when champs_public_attributes is empty' do
      let(:values) { [] }

      it "does nothing" do
        expect(dossier).not_to receive(:save)
        fill
      end
    end

    context 'when champs_public_attributes has values' do
      context 'when the champs are valid' do
        let(:types_de_champ_public) { [{ type: :text }, { type: :phone }] }
        let(:type_de_champ_1) { procedure.published_revision.types_de_champ_public.first }
        let(:value_1) { "any value" }
        let(:champ_id_1) { find_champ_by_stable_id(dossier, type_de_champ_1.stable_id).id }

        let(:type_de_champ_2) { procedure.published_revision.types_de_champ_public.second }
        let(:value_2) { "33612345678" }
        let(:champ_id_2) { find_champ_by_stable_id(dossier, type_de_champ_2.stable_id).id }

        let(:values) { [{ id: champ_id_1, value: value_1 }, { id: champ_id_2, value: value_2 }] }

        it "updates the champs with the new values and mark them as prefilled" do
          fill

          expect(dossier.champs_public.first.value).to eq(value_1)
          expect(dossier.champs_public.first.prefilled).to eq(true)
          expect(dossier.champs_public.last.value).to eq(value_2)
          expect(dossier.champs_public.last.prefilled).to eq(true)
        end
      end

      context 'when a champ is invalid' do
        let(:types_de_champ_public) { [{ type: :phone }] }
        let(:type_de_champ_1) { procedure.published_revision.types_de_champ_public.first }
        let(:value) { "a non phone value" }
        let(:champ_id) { find_champ_by_stable_id(dossier, type_de_champ_1.stable_id).id }

        let(:values) { [{ id: champ_id, value: value }] }

        it "still updates the champ" do
          expect { fill }.to change { dossier.champs_public.first.value }.from(nil).to(value)
        end

        it "still marks it as prefilled" do
          expect { fill }.to change { dossier.champs_public.first.prefilled }.from(nil).to(true)
        end
      end
    end
  end

  private

  def find_champ_by_stable_id(dossier, stable_id)
    dossier.champs.joins(:type_de_champ).find_by(types_de_champ: { stable_id: stable_id })
  end
end
