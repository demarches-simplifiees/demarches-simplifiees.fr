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
        dgfip: {},
        caf: {},
        pole_emploi: {},
        mesri: {}
      }
    end

    it { expect(subject).to eql(data) }
  end

  context "with dgfip_adresse' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:dgfip_adresse]] }

    let(:numero_fiscal) { "2097699999077" }
    let(:reference_de_l_avis) { "2097699999077" }

    let(:individual) do
      Individual.new(
        api_particulier_dgfip_numero_fiscal: numero_fiscal,
        api_particulier_dgfip_reference_de_l_avis: reference_de_l_avis
      )
    end

    context "but without selected sources" do
      let(:sources) { nil }

      let(:data) do
        { dgfip: {}, caf: {}, pole_emploi: {}, mesri: {} }
      end

      it "ne doit pas retrouver les données liées au foyer fiscal" do
        expect(subject).to eql(data)
      end
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          dgfip: { foyer_fiscal: { annee: 0, adresse: 1 } }
        }
      end

      let(:foyer_fiscal) do
        APIParticulier::Entities::DGFIP::FoyerFiscal.new(annee: 2020, adresse: "13 rue de la Plage 97615 Pamanzi")
      end

      let(:data) do
        {
          dgfip: { foyer_fiscal: foyer_fiscal },
          caf: {},
          pole_emploi: {},
          mesri: {}
        }
      end

      it "doit retrouver les donnnées liées au foyer fiscal" do
        VCR.use_cassette("api_particulier/success/avis_imposition") do
          expect(subject).to eq(data)
        end
      end
    end
  end

  context "with 'dgfip_avis_imposition' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:dgfip_avis_imposition]] }

    let(:numero_fiscal) { "2097699999077" }
    let(:reference_de_l_avis) { "2097699999077" }

    let(:individual) do
      Individual.new(
        api_particulier_dgfip_numero_fiscal: numero_fiscal,
        api_particulier_dgfip_reference_de_l_avis: reference_de_l_avis
      )
    end

    context "but without selected sources" do
      let(:sources) { nil }

      let(:data) do
        { dgfip: {}, caf: {}, pole_emploi: {}, mesri: {} }
      end

      it "ne doit pas retrouver les données liées à l'avis d'imposition" do
        expect(subject).to eql(data)
      end
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          dgfip: {
            avis_imposition: {
              declarant1: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 }
            }
          }
        }
      end

      let(:foyer_fiscal_inconnu) do
        APIParticulier::Entities::DGFIP::FoyerFiscal.new
      end

      let(:avis) do
        APIParticulier::Entities::DGFIP::AvisImposition.new(
          declarant1: { nom: "FERRI", nom_de_naissance: "FERRI", prenoms: "Karine", date_de_naissance: "12/08/1978" },
          declarant2: { nom: "", nom_de_naissance: "", prenoms: "", date_de_naissance: "12/08/1978" },
          date_de_recouvrement: "09/10/2020",
          date_d_etablissement: "07/07/2020",
          nombre_de_parts: 1,
          nombre_de_personnes_a_charge: 0,
          revenu_brut_global: 38814,
          revenu_imposable: 38814,
          impot_revenu_net_avant_corrections: 38814,
          montant_de_l_impot: 38814,
          revenu_fiscal_de_reference: 38814,
          annee_d_imposition: "2020",
          annee_des_revenus: "2020",
          situation_partielle: "SUP DOM"
        )
      end

      let(:data) do
        {
          dgfip: { avis_imposition: avis },
          caf: {},
          pole_emploi: {},
          mesri: {}
        }
      end

      it "doit retrouver les donnnées liées à l'avis d'imposition" do
        VCR.use_cassette("api_particulier/success/avis_imposition") do
          expect(subject).to eq(data)
          expect(subject.dig(:dgfip, :avis_imposition).foyer_fiscal).to eq foyer_fiscal_inconnu
        end
      end
    end
  end

  context "with all DGFIP scopes" do
    let(:scopes) do
      [
        APIParticulier::Types::Scope[:dgfip_avis_imposition],
        APIParticulier::Types::Scope[:dgfip_adresse]
      ]
    end

    let(:numero_fiscal) { "2097699999077" }
    let(:reference_de_l_avis) { "2097699999077" }

    let(:individual) do
      Individual.new(
        api_particulier_dgfip_numero_fiscal: numero_fiscal,
        api_particulier_dgfip_reference_de_l_avis: reference_de_l_avis
      )
    end

    context "but without selected sources" do
      let(:sources) { nil }

      let(:data) do
        { dgfip: {}, caf: {}, pole_emploi: {}, mesri: {} }
      end

      it "ne doit pas retrouver les données liées à l'avis d'imposition et au foyer fiscal" do
        expect(subject).to eql(data)
      end
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          dgfip: {
            foyer_fiscal: { annee: 0, adresse: 1 },
            avis_imposition: {
              declarant1: { nom: 1, prenoms: 0, nom_de_naissance: 0, date_de_naissance: 1 }
            }
          }
        }
      end

      let(:foyer_fiscal) do
        APIParticulier::Entities::DGFIP::FoyerFiscal.new(annee: 2020, adresse: "13 rue de la Plage 97615 Pamanzi")
      end

      let(:avis) do
        APIParticulier::Entities::DGFIP::AvisImposition.new(
          declarant1: { nom: "FERRI", nom_de_naissance: "FERRI", prenoms: "Karine", date_de_naissance: "12/08/1978" },
          declarant2: { nom: "", nom_de_naissance: "", prenoms: "", date_de_naissance: "12/08/1978" },
          date_de_recouvrement: "09/10/2020",
          date_d_etablissement: "07/07/2020",
          nombre_de_parts: 1,
          nombre_de_personnes_a_charge: 0,
          revenu_brut_global: 38814,
          revenu_imposable: 38814,
          impot_revenu_net_avant_corrections: 38814,
          montant_de_l_impot: 38814,
          revenu_fiscal_de_reference: 38814,
          annee_d_imposition: "2020",
          annee_des_revenus: "2020",
          situation_partielle: "SUP DOM"
        )
      end

      let(:data) do
        {
          dgfip: { avis_imposition: avis, foyer_fiscal: foyer_fiscal },
          caf: {},
          pole_emploi: {},
          mesri: {}
        }
      end

      it "doit retrouver les donnnées liées à l'avis d'imposition et au foyer fiscal" do
        VCR.use_cassette("api_particulier/success/avis_imposition") do
          expect(subject).to eq(data)
        end
      end
    end
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
        { dgfip: {}, caf: {}, pole_emploi: {}, mesri: {} }
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
          dgfip: {},
          caf: {
            allocataires: famille.allocataires,
            enfants: famille.enfants,
            adresse: famille.adresse,
            quotient_familial: famille.quotient_familial,
            annee: famille.annee,
            mois: famille.mois
          },
          pole_emploi: {},
          mesri: {}
        }
      end

      it "doit retrouver les donnnées liées à la CAF" do
        VCR.use_cassette("api_particulier/success/composition_familiale") do
          expect(subject).to eq(data)
        end
      end
    end
  end

  context "with 'pe_situation_individu' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:pe_situation_individu]] }
    let(:identifiant) { "georges_moustaki_77" }

    let(:individual) do
      Individual.new(api_particulier_pole_emploi_identifiant: identifiant)
    end

    context "but without selected sources" do
      let(:sources) { nil }

      let(:data) do
        { dgfip: {}, caf: {}, pole_emploi: {}, mesri: {} }
      end

      it "ne doit pas retrouver les données liées à Pôle Emploi" do
        expect(subject).to eql(data)
      end
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          pole_emploi: { situation: { email: 1, nom: 0 } }
        }
      end

      let(:situation) do
        APIParticulier::Entities::PoleEmploi::SituationPoleEmploi.new(
          email: "georges@moustaki.fr",
          nom: "Moustaki",
          nom_d_usage: "Moustaki",
          prenom: "Georges",
          identifiant: identifiant,
          sexe: "M",
          date_de_naissance: "1934-05-03T00:00:00",
          date_d_inscription: "1965-05-03T00:00:00",
          date_de_radiation: "1966-05-03T00:00:00",
          date_de_la_prochaine_convocation: "1966-05-03T00:00:00",
          categorie_d_inscription: "3",
          code_de_certification_cnav: "VC",
          telephone: "0629212921",
          civilite: "M.",
          adresse: {
            code_postal: "75018",
            insee_commune: "75118",
            localite: "75018 Paris",
            ligne_voie: "3 rue des Huttes",
            ligne_nom_du_detinataire: "MOUSTAKI"
          }
        )
      end

      let(:data) do
        {
          dgfip: {},
          caf: {},
          pole_emploi: { situation: situation },
          mesri: {}
        }
      end

      it "doit retrouver les donnnées liées à Pôle Emploi" do
        VCR.use_cassette("api_particulier/success/situation_pole_emploi") do
          expect(subject).to eq(data)
        end
      end
    end
  end

  context "with 'mesri_statut_etudiant' scope" do
    let(:scopes) { [APIParticulier::Types::Scope[:mesri_statut_etudiant]] }
    let(:ine) { "0906018155T" }

    let(:individual) do
      Individual.new(api_particulier_mesri_ine: ine)
    end

    context "but without selected sources" do
      let(:sources) { nil }

      let(:data) do
        { dgfip: {}, caf: {}, pole_emploi: {}, mesri: {} }
      end

      it "ne doit pas retrouver les données liées au statut étudiant" do
        expect(subject).to eql(data)
      end
    end

    context "and some sources are selected" do
      let(:sources) do
        {
          mesri: {
            statut_etudiant: { inscriptions: { etablissement: { nom: 1, uai: 0 } } }
          }
        }
      end

      let(:etudiant) do
        APIParticulier::Entities::MESRI::Etudiant.new(
          ine: ine,
          nom: "Dupont",
          prenom: "Gaëtan",
          date_de_naissance: "1999-10-12T00:00:00",
          inscriptions: [
            {
              date_de_debut_d_inscription: "2019-09-01T00:00:00",
              date_de_fin_d_inscription: "2020-08-31T00:00:00",
              statut: "admis",
              regime: "formation initiale",
              code_commune: "44000",
              etablissement: {
                uai: "0011402U",
                nom: "EGC AIN BOURG EN BRESSE EC GESTION ET COMMERCE (01000)"
              }
            }
          ]
        )
      end

      let(:data) do
        {
          dgfip: {},
          caf: {},
          pole_emploi: {},
          mesri: { statut_etudiant: etudiant }
        }
      end

      it "doit retrouver les donnnées liées au statut étudiant" do
        VCR.use_cassette("api_particulier/success/etudiants") do
          expect(subject).to eq(data)
        end
      end
    end
  end
end
