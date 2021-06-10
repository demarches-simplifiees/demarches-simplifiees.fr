# frozen_string_literal: true

describe APIParticulier::Services::SanitizeData do
  let(:famille_attrs) do
    {
      adresse: {
        identite: "Madame MARIE DUPONT",
        complement_d_identite: "ESCALIER B",
        complement_d_identite_geo: nil,
        numero_et_rue: "123 RUE BIDON",
        code_postal_et_ville: "12345 CONDAT",
        lieu_dit: nil,
        pays: "FRANCE"
      },
      allocataires: [
        {
          noms_et_prenoms: "MARIE DUPONT",
          date_de_naissance: "12111971",
          sexe: "F"
        }, {
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
  end

  let(:famille) { APIParticulier::Entities::CAF::Famille.new(**famille_attrs) }

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

  let(:service) { APIParticulier::Services::SanitizeData.new }

  subject { service.call(data, mask) }

  context "quand on picore des données un peu partout" do
    let(:mask) do
      {
        caf: {
          adresse: {
            code_postal_et_ville: 1,
            complement_d_identite: 0,
            complement_d_identite_geo: 0,
            identite: 0,
            lieu_dit: 0,
            numero_et_rue: 0,
            pays: 1
          },
          allocataires: { date_de_naissance: 0, noms_et_prenoms: 1, sexe: 1 },
          annee: 1,
          enfants: { date_de_naissance: 1, noms_et_prenoms: 0, sexe: 1 },
          mois: 0,
          quotient_familial: 1
        }
      }
    end

    let(:famille_assainie) do
      {
        adresse: {
          code_postal_et_ville: "12345 CONDAT",
          pays: "FRANCE"
        },
        allocataires: [
          { noms_et_prenoms: "MARIE DUPONT", sexe: "F" },
          { noms_et_prenoms: "JEAN DUPONT", sexe: "M" }
        ],
        enfants: [
          { date_de_naissance: "11122016", sexe: "F" }
        ],
        quotient_familial: 1754,
        annee: 2020
      }
    end

    let(:sanitized_data) do
      {
        caf: famille_assainie
      }
    end

    it "doit retourner les seules informations retenues" do
      expect(subject).to eq(sanitized_data)
    end
  end

  context "quand on ne veut récupérer que le quotient familial" do
    let(:mask) do
      {
        caf: { quotient_familial: 1 }
      }
    end

    let(:sanitized_data) do
      {
        caf: { quotient_familial: 1754 }
      }
    end

    it "ne doit retourner aucune informations" do
      expect(subject).to eq(sanitized_data)
    end
  end

  context "quand on ne veut récupérer aucune donnée" do
    let(:mask) do
      {
        caf: {}
      }
    end

    let(:sanitized_data) do
      {
        caf: {}
      }
    end

    it "ne doit retourner aucune informations" do
      expect(subject).to eq(sanitized_data)
    end
  end

  context "quand on veut récupérer toutes les données" do
    let(:mask) do
      {
        caf: {
          adresse: {
            code_postal_et_ville: 1,
            complement_d_identite: 1,
            complement_d_identite_geo: 1,
            identite: 1,
            lieu_dit: 1,
            numero_et_rue: 1,
            pays: 1
          },
          allocataires: { date_de_naissance: 1, noms_et_prenoms: 1, sexe: 1 },
          annee: 1,
          enfants: { date_de_naissance: 1, noms_et_prenoms: 1, sexe: 1 },
          mois: 1,
          quotient_familial: 1
        }
      }
    end

    let(:sanitized_data) do
      {
        caf: famille_attrs
      }
    end

    it "doit retourner toutes informations" do
      expect(subject).to eq(sanitized_data)
    end
  end
end
