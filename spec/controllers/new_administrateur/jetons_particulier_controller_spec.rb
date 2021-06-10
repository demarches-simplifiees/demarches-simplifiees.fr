describe NewAdministrateur::JetonsParticulierController, type: :controller do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateur: admin) }

  before do
    Flipper.enable(:api_particulier)
    sign_in(admin.user)
  end

  describe "GET #index" do
    render_views

    subject { get :index, params: { procedure_id: procedure.id } }

    context "when feature API Particulier is enable" do
      it { is_expected.to have_http_status(:success) }
      it { expect(subject.body).not_to have_content("Fonctionnalité désctivée") }
    end

    context "when feature API Particulier is disable" do
      before do
        Flipper.disable(:api_particulier)
      end

      it { is_expected.to have_http_status(:success) }
      it { expect(subject.body).to have_content("Fonctionnalité désctivée") }
    end
  end

  describe "GET #jeton" do
    subject { get :jeton, params: { procedure_id: procedure.id } }

    it { is_expected.to have_http_status(:success) }
  end

  describe "PATCH #update_jeton" do
    let(:params) { { procedure_id: procedure.id, procedure: { api_particulier_token: token } } }

    subject { patch :update_jeton, params: params }

    context "when jeton is valid" do
      let(:token) { "3841b13fa8032ed3c31d160d3437a76a" }

      let(:scopes) do
        ['dgfip_avis_imposition', 'dgfip_adresse', 'cnaf_allocataires', 'cnaf_enfants', 'cnaf_adresse', 'cnaf_quotient_familial', 'mesri_statut_etudiant']
      end

      before do
        VCR.use_cassette("api_particulier/success/introspect") do
          subject
        end
      end

      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eql("Le jeton a bien été mis à jour") }
      it { expect(procedure.reload.api_particulier_token).to eql(token) }
      it { expect(procedure.reload.api_particulier_scopes).to match_array(scopes) }
      it { expect(procedure.reload.api_particulier_sources).to be_empty }
    end

    context "when jeton is invalid" do
      let(:token) { "jet0n 1nvalide" }

      before do
        VCR.use_cassette("api_particulier/not_found/introspect") do
          subject
        end
      end

      it { expect(flash.alert).to eql("Mise à jour impossible : le jeton n'est pas valide") }
      it { expect(flash.notice).to be_nil }
      it { expect(procedure.reload.api_particulier_token).not_to eql(token) }
      it { expect(procedure.reload.api_particulier_scopes).to be_empty }
      it { expect(procedure.reload.api_particulier_sources).to be_empty }
    end

    context "when token is missing" do
      let(:params) { { procedure_id: procedure.id } }

      before do
        subject
      end

      it { expect(flash.alert).to eql("Mise à jour impossible : le jeton n'est pas valide") }
      it { expect(flash.notice).to be_nil }
      it { expect(procedure.reload.api_particulier_token).to be_nil }
      it { expect(procedure.reload.api_particulier_scopes).to be_empty }
      it { expect(procedure.reload.api_particulier_sources).to be_empty }
    end
  end

  describe "GET #sources" do
    subject { get :sources, params: { procedure_id: procedure.id } }

    it { is_expected.to have_http_status(:success) }
  end

  describe "PATCH #update_sources" do
    let(:sources_params) do
      {
        dgfip: {
          avis_imposition: {
            declarant1: {
              nom: 1,
              nom_de_naissance: 0,
              prenoms: 0,
              date_de_naissance: 0
            },
            declarant2: {
              nom: 1,
              nom_de_naissance: 0,
              prenoms: 0,
              date_de_naissance: 0
            },
            date_de_recouvrement: 0,
            date_d_etablissement: 0,
            nombre_de_parts: 1,
            situation_familiale: 1,
            nombre_de_personnes_a_charge: 0,
            revenu_brut_global: 0,
            revenu_imposable: 0,
            impot_revenu_net_avant_corrections: 0,
            montant_de_l_impot: 0,
            revenu_fiscal_de_reference: 0,
            annee_d_imposition: 0,
            annee_des_revenus: 0,
            erreur_correctif: 0,
            situation_partielle: 0
          },
          foyer_fiscal: {
            annee: 0,
            adresse: 0
          }
        },
        caf: {
          allocataires: {
            noms_et_prenoms: 1,
            date_de_naissance: 1,
            sexe: 1
          },
          enfants: {
            noms_et_prenoms: 0,
            date_de_naissance: 0,
            sexe: 0
          },
          adresse: {
            identite: 0,
            complement_d_identite: 0,
            complement_d_identite_geo: 0,
            numero_et_rue: 0,
            lieu_dit: 0,
            code_postal_et_ville: 0,
            pays: 0
          },
          quotient_familial: {
            quotient_familial: 1,
            annee: 0,
            mois: 0
          }
        },
        pole_emploi: {
          situation: {
            email: 1,
            nom: 0,
            nom_d_usage: 0,
            prenom: 0,
            identifiant: 0,
            sexe: 0,
            date_de_naissance: 0,
            date_d_inscription: 0,
            date_de_radiation: 0,
            date_de_la_prochaine_convocation: 0,
            categorie_d_inscription: 0,
            code_de_certification_cnav: 0,
            telephone: 0,
            telephone2: 0,
            civilite: 0,
            adresse: {
              code_postal: 0,
              insee_commune: 1,
              localite: 0,
              ligne_voie: 0,
              ligne_complement_destinataire: 0,
              ligne_complement_d_adresse: 0,
              ligne_complement_de_distribution: 0,
              ligne_nom_du_detinataire: 0
            }
          }
        },
        mesri: {
          statut_etudiant: {
            ine: 1,
            nom: 0,
            prenom: 0,
            date_de_naissance: 0,
            inscriptions: {
              date_de_debut_d_inscription: 0,
              date_de_fin_d_inscription: 0,
              statut: 1,
              regime: 0,
              code_commune: 0,
              etablissement: {
                uai: 1,
                nom: 1
              }
            }
          }
        }
      }
    end

    let(:params) { { procedure: sources_params, procedure_id: procedure.id } }

    subject { patch :update_sources, params: params }

    before do
      subject
    end

    context "when params are valid" do
      it { expect(flash.alert).to be_nil }
      it { expect(flash.notice).to eql("Les sources de données ont bien été mises à jour") }
      it { expect(procedure.reload.api_particulier_sources).to eql(sources_params) }
    end

    context "when params are invalid" do
      let(:params) { { procedure_id: procedure.id } }

      it { expect(flash.alert).to eql("Mise à jour impossible : les sources de données ne sont pas valides") }
      it { expect(flash.notice).to be_nil }
      it { expect(procedure.reload.api_particulier_sources).to be_empty }
    end
  end
end
