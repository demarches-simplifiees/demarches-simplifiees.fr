# frozen_string_literal: true

describe APIParticulier::Services::BuildData do
  let(:service) { APIParticulier::Services::BuildData.new }

  subject { service.call(raw: raw) }

  context "without data" do
    let(:raw) do
      {
        caf: {}
      }
    end

    let(:data) do
      {
        caf: nil
      }
    end

    it { expect(subject).to eql(data) }
  end

  context "with some data" do
    let(:raw) do
      {
        caf: {
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
        caf: famille
      }
    end

    it { expect(subject).to eq(data) }
  end
end
