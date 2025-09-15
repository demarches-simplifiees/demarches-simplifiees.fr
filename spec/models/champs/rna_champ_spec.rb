# frozen_string_literal: true

describe Champs::RNAChamp do
  let(:types_de_champ_public) { [{ type: :rna }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first.tap { _1.update(value:) } }
  let(:value) { "W182736273" }

  def with_value(value, data)
    champ.tap do
      _1.value = value
      _1.data = data
    end
  end

  describe '#valid?' do
    it do
      expect(with_value(nil, nil).validate(:champs_public_value)).to be_truthy
      expect(with_value("2736251627", nil).validate(:champs_public_value)).to be_falsey
      expect(with_value("A172736283", nil).validate(:champs_public_value)).to be_falsey
      expect(with_value("W1827362718", nil).validate(:champs_public_value)).to be_falsey
      expect(with_value("W182736273", nil).validate(:champs_public_value)).to be_falsey
      expect(with_value("W182736273", { "api" => "response" }).validate(:champs_public_value)).to be_truthy
    end

    it 'when invalid format, it contains only error message for invalid format' do
      champ = with_value("W1827362", nil)
      champ.validate(:champs_public_value)
      expect(champ.errors.full_messages).to eq(["doit commencer par un W majuscule suivi de 9 chiffres ou lettres. Exemple : W503726238"])
    end

    it 'when valid format, but no data, it contains only error message for not found' do
      champ = with_value("W182736273", nil)
      champ.validate(:champs_public_value)
      expect(champ.errors.full_messages).to eq(["le numéro RNA W182736273 saisi ne correspond à aucun établissement, saisissez un numéro RNA valide"])
    end
  end

  describe "#export" do
    context "with association title" do
      before do
        champ.update(data: { association_titre: "Super asso" })
      end

      it { expect(champ.type_de_champ.champ_value_for_export(champ)).to eq("W182736273 (Super asso)") }
    end

    context "no association title" do
      it { expect(champ.type_de_champ.champ_value_for_export(champ)).to eq("W182736273") }
    end
  end
end
