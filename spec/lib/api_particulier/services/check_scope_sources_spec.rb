# frozen_string_literal: true

describe APIParticulier::Services::CheckScopeSources do
  let(:scopes) { nil }

  let(:sources) do
    {
      caf: {
        mois: 0,
        annee: 0,
        adresse: {
          pays: 0,
          identite: 0,
          lieu_dit: 0,
          numero_et_rue: 0,
          code_postal_et_ville: 0,
          complement_d_identite: 0,
          complement_d_identite_geo: 0
        },
        enfants: { sexe: 0, noms_et_prenoms: 0, date_de_naissance: 0 },
        allocataires: { sexe: 0, noms_et_prenoms: 1, date_de_naissance: 0 },
        quotient_familial: 1
      }
    }
  end

  let(:service) { APIParticulier::Services::CheckScopeSources.new(scopes, sources) }

  context "without scopes" do
    let(:scopes) { [] }
    let(:sources) { nil }

    it { expect(service.call(nil)).to be false }
    it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
  end

  context "with all CAF scopes" do
    let(:scopes) do
      [
        APIParticulier::Types::Scope[:cnaf_allocataires],
        APIParticulier::Types::Scope[:cnaf_enfants],
        APIParticulier::Types::Scope[:cnaf_adresse],
        APIParticulier::Types::Scope[:cnaf_quotient_familial]
      ]
    end

    context "but no sources" do
      let(:sources) { nil }

      it { expect(service.call(nil)).to be false }
      it { expect(service.call("cnaf_allocataires")).to be false }
      it { expect(service.call("cnaf_enfants")).to be false }
      it { expect(service.call("cnaf_adresse")).to be false }
      it { expect(service.call("cnaf_quotient_familial")).to be false }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be false }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be false }
    end

    context "and some sources" do
      it { expect(service.call(nil)).to be false }
      it { expect(service.call("cnaf_allocataires")).to be true }
      it { expect(service.call("cnaf_enfants")).to be false }
      it { expect(service.call("cnaf_adresse")).to be false }
      it { expect(service.call("cnaf_quotient_familial")).to be true }
      it { expect(service.call(APIParticulier::Types::CAF_SCOPES)).to be true }
      it { expect(service.call(APIParticulier::Types::SCOPES)).to be true }
    end
  end
end
