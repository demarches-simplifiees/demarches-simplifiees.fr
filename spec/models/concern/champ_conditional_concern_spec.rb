describe ChampConditionalConcern do
  include Logic

  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :number }, { type: :number }]) }
  let(:dossier) { create(:dossier, revision: procedure.active_revision) }
  let(:types_de_champ) { procedure.active_revision.types_de_champ_public }
  let(:champ) { create(:champ, dossier:, type_de_champ: types_de_champ.first, value: 1) }

  describe '#dependent_conditions?' do
    context "when there are no condition" do
      it { expect(champ.dependent_conditions?).to eq(false) }
    end

    context "when other tdc has a condition" do
      before do
        condition = ds_eq(champ_value(champ.stable_id), constant(1))
        types_de_champ.last.update!(condition:)
      end

      it { expect(champ.dependent_conditions?).to eq(true) }
    end
  end
end
