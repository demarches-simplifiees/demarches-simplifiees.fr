describe ChampConditionalConcern do
  include Logic

  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :decimal_number, stable_id: 99 }, { type: :decimal_number, condition: }]) }
  let(:dossier) { create(:dossier, revision: procedure.active_revision) }
  let(:types_de_champ) { procedure.active_revision.types_de_champ_public }
  let(:champ) { create(:champ_decimal_number, dossier:, type_de_champ: types_de_champ.first, value: '1.1234') }
  let(:last_champ) { create(:champ_decimal_number, dossier:, type_de_champ: types_de_champ.last, value: '1.1234') }
  let(:condition) { nil }

  describe '#dependent_conditions?' do
    context "when there are no condition" do
      it { expect(champ.dependent_conditions?).to eq(false) }
    end

    context "when other tdc has a condition" do
      let(:condition) { ds_eq(champ_value(99), constant(1)) }

      it { expect(champ.dependent_conditions?).to eq(true) }
    end
  end

  describe '#visible?' do
    context "when there are no condition" do
      it {
        expect(champ.visible?).to eq(true)
        expect(champ.valid?(:champs_public_value)).to eq(false)

        expect(last_champ.visible?).to eq(true)
        expect(last_champ.valid?(:champs_public_value)).to eq(false)
      }
    end

    context "when other tdc has a condition" do
      let(:condition) { ds_eq(champ_value(99), constant(1)) }

      it {
        expect(champ.visible?).to eq(true)
        expect(champ.valid?(:champs_public_value)).to eq(false)

        expect(last_champ.visible?).to eq(false)
        expect(last_champ.valid?(:champs_public_value)).to eq(true)
      }
    end
  end
end
