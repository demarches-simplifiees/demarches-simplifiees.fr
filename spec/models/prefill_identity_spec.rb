# frozen_string_literal: true

RSpec.describe PrefillIdentity do
  describe "#to_h" do
    let(:dossier) { create(:dossier, :brouillon, :with_individual) }

    subject(:prefill_identity_hash) { described_class.new(dossier, params).to_h }

    context "if genre is correct" do
      let(:params) {
        {
          "identite_prenom" => "Prénom",
          "identite_nom" => "Nom",
        }
      }

      it "builds an array of hash(id, value) matching all the given params" do
        expect(prefill_identity_hash).to match({ prenom: "Prénom", nom: "Nom", gender: nil })
      end
    end
  end
end
