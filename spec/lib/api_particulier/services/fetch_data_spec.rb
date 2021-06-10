# frozen_string_literal: true

describe APIParticulier::Services::FetchData do
  let(:procedure) { Procedure.new(api_particulier_scopes: scopes, api_particulier_sources: sources) }
  let(:dossier) { Dossier.new(procedure: procedure, individual: individual) }
  let(:service) { APIParticulier::Services::FetchData.new(dossier) }

  subject { service.call }

  context "without scope" do
    let(:scopes) { [] }
    let(:sources) { nil }
    let(:individual) { Individual.new }

    let(:data) do
      {
        caf: {}
      }
    end

    it { expect(subject).to eql(data) }
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

    let(:code_postal) { "99148" }
    let(:numero_d_allocataire) { "0000354" }

    let(:individual) do
      Individual.new(
        api_particulier_caf_code_postal: code_postal,
        api_particulier_caf_numero_d_allocataire: numero_d_allocataire
      )
    end

    context "but without selected sources" do
      let(:sources) { nil }

      let(:data) do
        { caf: {} }
      end

      it "ne doit pas retrouver les données liées à la CAF" do
        expect(subject).to eql(data)
      end
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

      let(:famille) do
        APIParticulier::Entities::CAF::Famille.new(
          adresse: {
            identite: "Madame MARIE DUPONT",
            complement_d_identite_geo: "ESCALIER B",
            numero_et_rue: "123 RUE BIDON",
            code_postal_et_ville: "12345 CONDAT",
            pays: "FRANCE"
          },
          allocataires: [
            {
              noms_et_prenoms: "MARIE DUPONT",
              date_de_naissance: "12111971",
              sexe: "F"
            },
            {
              noms_et_prenoms: "JEAN DUPONT",
              date_de_naissance: "18101969",
              sexe: "M"
            }
          ],
          enfants: [
            {
              noms_et_prenoms: "LUCIE DUPONT",
              date_de_naissance: "11122016",
              sexe: "F"
            }
          ],
          quotient_familial: 1754,
          annee: 2020,
          mois: 12
        )
      end

      let(:data) do
        {
          caf: {
            allocataires: famille.allocataires,
            enfants: famille.enfants,
            adresse: famille.adresse,
            quotient_familial: famille.quotient_familial,
            annee: famille.annee,
            mois: famille.mois
          }
        }
      end

      it "doit retrouver les donnnées liées à la CAF" do
        VCR.use_cassette("api_particulier/success/composition_familiale") do
          expect(subject).to eq(data)
        end
      end
    end
  end
end
