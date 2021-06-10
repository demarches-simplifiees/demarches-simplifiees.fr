# frozen_string_literal: true

describe APIParticulier::Services::BuildProcedureMask do
  let(:procedure) { Procedure.new(api_particulier_scopes: scopes, api_particulier_sources: sources) }
  let(:service) { APIParticulier::Services::BuildProcedureMask.new(procedure) }

  subject { service.call }

  context "without scope" do
    let(:scopes) { [] }
    let(:sources) { nil }

    let(:built_mask) do
      {
        caf: {}
      }
    end

    it { expect(subject).to eql(built_mask) }
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

    let(:built_mask) do
      {
        caf: {
          adresse: {
            code_postal_et_ville: nil,
            complement_d_identite: nil,
            complement_d_identite_geo: nil,
            identite: nil,
            lieu_dit: nil,
            numero_et_rue: nil,
            pays: nil
          },
          allocataires: { date_de_naissance: nil, noms_et_prenoms: nil, sexe: nil },
          annee: nil,
          enfants: { date_de_naissance: nil, noms_et_prenoms: nil, sexe: nil },
          mois: nil,
          quotient_familial: nil
        }
      }
    end

    context "but without selected sources" do
      let(:sources) { nil }

      it { expect(subject).to eql(built_mask) }
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          caf: {
            allocataires: { sexe: 0, noms_et_prenoms: 1, date_de_naissance: 0 },
            quotient_familial: 1
          }
        }
      end

      it { expect(subject).to eql(built_mask) }
    end
  end
end
