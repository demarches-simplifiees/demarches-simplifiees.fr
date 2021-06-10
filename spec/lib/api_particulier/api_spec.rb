# frozen_string_literal: true

describe APIParticulier::API do
  let(:token) { "d7e9c9f4c3ca00caadde31f50fd4521a" }
  let(:api) { APIParticulier::API.new(token: token) }

  describe "avis d'imposition" do
    subject { api.avis_d_imposition(numero_fiscal: numero_fiscal, reference_de_l_avis: reference_de_l_avis) }

    context "avec un numéro fiscal et une référence d'avis valides" do
      let(:numero_fiscal) { "2097699999077" }
      let(:reference_de_l_avis) { "2097699999077" }

      it "doit retourner un avis valide" do
        VCR.use_cassette("api_particulier/success/avis_imposition") do
          expect(subject).to be_instance_of(APIParticulier::Entities::DGFIP::AvisImposition)

          expect(subject.declarant1).to be_instance_of(APIParticulier::Entities::DGFIP::Declarant)
          expect(subject.declarant1.nom).to eql("FERRI")
          expect(subject.declarant1.nom_de_naissance).to eql("FERRI")
          expect(subject.declarant1.prenoms).to eql("Karine")
          expect(subject.declarant1.date_de_naissance).to eql(Date.new(1978, 8, 12))

          expect(subject.declarant2).to be_instance_of(APIParticulier::Entities::DGFIP::Declarant)

          expect(subject.foyer_fiscal).to be_instance_of(APIParticulier::Entities::DGFIP::FoyerFiscal)
          expect(subject.foyer_fiscal.annee).to equal(2020)
          expect(subject.foyer_fiscal.adresse).to eql("13 rue de la Plage 97615 Pamanzi")

          expect(subject.date_de_recouvrement).to eql(Date.new(2020, 10, 9))
          expect(subject.date_d_etablissement).to eql(Date.new(2020, 7, 7))
          expect(subject.nombre_de_parts).to equal(1.0)
          expect(subject.situation_familiale).to be_nil
          expect(subject.nombre_de_personnes_a_charge).to equal(0)
          expect(subject.revenu_brut_global).to equal(38814)
          expect(subject.revenu_imposable).to equal(38814)
          expect(subject.impot_revenu_net_avant_corrections).to equal(38814)
          expect(subject.montant_de_l_impot).to equal(38814)
          expect(subject.revenu_fiscal_de_reference).to equal(38814)
          expect(subject.annee_d_imposition).to equal(2020)
          expect(subject.annee_des_revenus).to equal(2020)
          expect(subject.erreur_correctif).to be_nil
          expect(subject.situation_partielle).to eql("SUP DOM")
        end
      end
    end

    context "avec une référence d'avis comportant une lettre" do
      let(:numero_fiscal) { "2097699999077" }
      let(:reference_de_l_avis) { "2097699999077A" }

      it "doit retourner un avis valide" do
        VCR.use_cassette("api_particulier/success/avis_imposition") do
          expect(subject).to be_instance_of(APIParticulier::Entities::DGFIP::AvisImposition)
        end
      end
    end

    context "avec un numéro fiscal inconnu" do
      let(:numero_fiscal) { "0000000000000" }
      let(:reference_de_l_avis) { "2097699999077" }

      it "doit retourner une erreur" do
        VCR.use_cassette("api_particulier/not_found/avis_imposition") do
          expect { subject }.to raise_error(APIParticulier::Error::NotFound)
        end
      end
    end
  end

  describe "composition familiale" do
    subject { api.composition_familiale(numero_d_allocataire: numero_d_allocataire, code_postal: code_postal) }

    context "avec un numéro d'allocataire et un code postal valides" do
      let(:numero_d_allocataire) { "0000354" }
      let(:code_postal) { "99148" }

      it "doit retourner une famille valide" do
        VCR.use_cassette("api_particulier/success/composition_familiale") do
          expect(subject).to be_instance_of(APIParticulier::Entities::CAF::Famille)
          expect(subject.allocataires).to be_instance_of(Array)
          expect(subject.allocataires.count).to equal(2)

          allocataire = subject.allocataires.first
          expect(allocataire).to be_instance_of(APIParticulier::Entities::CAF::Personne)
          expect(allocataire.noms_et_prenoms).to eql("MARIE DUPONT")
          expect(allocataire.date_de_naissance).to eql(Date.new(1971, 11, 12))
          expect(allocataire.sexe).to eql("féminin")

          expect(subject.enfants).to be_instance_of(Array)
          expect(subject.enfants.count).to equal(1)

          enfant = subject.enfants.first
          expect(enfant).to be_instance_of(APIParticulier::Entities::CAF::Personne)
          expect(enfant.noms_et_prenoms).to eql("LUCIE DUPONT")
          expect(enfant.date_de_naissance).to eql(Date.new(2016, 12, 11))
          expect(enfant.sexe).to eql("féminin")

          expect(subject.adresse).to be_instance_of(APIParticulier::Entities::CAF::PosteAdresse)
          expect(subject.adresse.identite).to eql("Madame MARIE DUPONT")
          expect(subject.adresse.complement_d_identite).to be_nil
          expect(subject.adresse.numero_et_rue).to eql("123 RUE BIDON")
          expect(subject.adresse.lieu_dit).to be_nil
          expect(subject.adresse.code_postal_et_ville).to eql("12345 CONDAT")
          expect(subject.adresse.pays).to eql("FRANCE")

          expect(subject.quotient_familial).to equal(1754)
          expect(subject.annee).to equal(2020)
          expect(subject.mois).to equal(12)
        end
      end
    end

    context "avec un numéro d'allocataire inconnu" do
       let(:numero_d_allocataire) { "0000000" }
       let(:code_postal) { "99148" }

       it "doit retourner une erreur" do
         VCR.use_cassette("api_particulier/not_found/composition_familiale") do
           expect { subject }.to raise_error(APIParticulier::Error::NotFound)
         end
       end
     end
  end

  describe "situation pôle emploi" do
    subject { api.situation_pole_emploi(identifiant: identifiant) }

    context "avec un identifiant valide" do
      let(:identifiant) { "georges_moustaki_77" }

      it "doit retourner une situation valide" do
        VCR.use_cassette("api_particulier/success/situation_pole_emploi") do
          expect(subject).to be_instance_of(APIParticulier::Entities::PoleEmploi::SituationPoleEmploi)
          expect(subject.email).to eql("georges@moustaki.fr")
          expect(subject.nom).to eql("Moustaki")
          expect(subject.nom_d_usage).to eql("Moustaki")
          expect(subject.prenom).to eql("Georges")
          expect(subject.identifiant).to eql(identifiant)
          expect(subject.sexe).to eql("masculin")
          expect(subject.date_de_naissance).to eql(DateTime.new(1934, 5, 3))
          expect(subject.date_d_inscription).to eql(DateTime.new(1965, 5, 3))
          expect(subject.date_de_radiation).to eql(DateTime.new(1966, 5, 3))
          expect(subject.date_de_la_prochaine_convocation).to eql(DateTime.new(1966, 5, 3))
          expect(subject.categorie_d_inscription).to eql("3")
          expect(subject.code_de_certification_cnav).to eql("VC")
          expect(subject.telephones).to be_instance_of(Array)
          expect(subject.telephones).to contain_exactly("0629212921")
          expect(subject.civilite).to eql("M.")
          expect(subject.adresse).to be_instance_of(APIParticulier::Entities::PoleEmploi::Adresse)
          expect(subject.adresse.code_postal).to eql("75018")
          expect(subject.adresse.insee_commune).to eql("75118")
          expect(subject.adresse.localite).to eql("75018 Paris")
          expect(subject.adresse.ligne_voie).to eql("3 rue des Huttes")
          expect(subject.adresse.ligne_complement_destinataire).to be_nil
          expect(subject.adresse.ligne_complement_d_adresse).to be_nil
          expect(subject.adresse.ligne_complement_de_distribution).to be_nil
          expect(subject.adresse.ligne_nom_du_detinataire).to eql("MOUSTAKI")
        end
      end
    end

    context "avec un identifiant inconnu" do
      let(:identifiant) { "0000000" }

      it "doit retourner une erreur" do
        VCR.use_cassette("api_particulier/not_found/situation_pole_emploi") do
          expect { subject }.to raise_error(APIParticulier::Error::NotFound)
        end
      end
    end
  end

  describe "étudiants" do
    subject { api.etudiants(ine: ine) }

    context "avec un INE valide" do
      let(:ine) { "0906018155T" }

      it "doit retourner un étudiant valide" do
        VCR.use_cassette("api_particulier/success/etudiants") do
          expect(subject).to be_instance_of(APIParticulier::Entities::MESRI::Etudiant)
          expect(subject.ine).to eql(ine)
          expect(subject.nom).to eql("Dupont")
          expect(subject.prenom).to eql("Gaëtan")
          expect(subject.date_de_naissance).to eql(DateTime.new(1999, 10, 12))
          expect(subject.inscriptions).to be_instance_of(Array)
          expect(subject.inscriptions.count).to equal(1)

          inscription = subject.inscriptions.first
          expect(inscription).to be_instance_of(APIParticulier::Entities::MESRI::Inscription)
          expect(inscription.date_de_debut_d_inscription).to eql(DateTime.new(2019, 9, 1))
          expect(inscription.date_de_fin_d_inscription).to eql(DateTime.new(2020, 8, 31))
          expect(inscription.statut).to eql("admis")
          expect(inscription.regime).to eql("formation initiale")
          expect(inscription.code_commune).to eql("44000")

          etablissement = inscription.etablissement
          expect(etablissement).to be_instance_of(APIParticulier::Entities::MESRI::Etablissement)
          expect(etablissement.uai).to eql("0011402U")
          expect(etablissement.nom).to eql("EGC AIN BOURG EN BRESSE EC GESTION ET COMMERCE (01000)")
        end
      end
    end

    context "avec un identifiant inconnu" do
      let(:ine) { "0000000000T" }

      it "doit retourner une erreur" do
        VCR.use_cassette("api_particulier/not_found/etudiants") do
          expect { subject }.to raise_error(APIParticulier::Error::NotFound)
        end
      end
    end
  end

  describe "introspect" do
    subject { api.introspect }

    it "doit retourner une introspection valide" do
      VCR.use_cassette("api_particulier/success/introspect") do
        expect(subject).to be_instance_of(APIParticulier::Entities::Introspection)
        expect(subject.id).to be_nil
        expect(subject.name).to eql("Application de sandbox")
        expect(subject.email).to be_nil
        expect(subject.scopes).to be_instance_of(Array)
        expect(subject.scopes).to match_array(['dgfip_avis_imposition', 'dgfip_adresse', 'cnaf_allocataires', 'cnaf_enfants', 'cnaf_adresse', 'cnaf_quotient_familial', 'mesri_statut_etudiant'])
      end
    end
  end

  describe "ping" do
    subject { api.ping? }

    it "doit répondre positivement" do
      VCR.use_cassette("api_particulier/success/ping") do
        expect(subject).to be true
      end
    end
  end
end
