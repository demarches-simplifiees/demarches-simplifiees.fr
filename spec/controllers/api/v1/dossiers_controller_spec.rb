require 'spec_helper'

describe API::V1::DossiersController do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_type_de_champ_private, administrateur: admin, cerfa_flag: true) }
  let(:wrong_procedure) { create(:procedure) }

  it { expect(described_class).to be < APIController }

  describe 'GET index (with bearer token)' do
    let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(admin.api_token) }
    let(:retour) do
      request.env['HTTP_AUTHORIZATION'] = authorization_header
      get :index, params: { procedure_id: procedure_id }
    end

    subject { retour }

    context 'when procedure is not found' do
      let(:procedure_id) { 99_999_999 }
      it { expect(subject.code).to eq('404') }
    end
  end

  describe 'GET index' do
    let(:retour) { get :index, params: { token: admin.api_token, procedure_id: procedure_id } }

    subject { retour }

    context 'when procedure is not found' do
      let(:procedure_id) { 99_999_999 }
      it { expect(subject.code).to eq('404') }
    end

    context 'when procedure does not belong to admin' do
      let(:procedure_id) { wrong_procedure.id }
      it { expect(subject.code).to eq('404') }
    end

    context 'when procedure is found and belongs to admin' do
      let(:procedure_id) { procedure.id }
      let(:date_creation) { Time.utc(2008, 9, 1, 10, 5, 0) }
      let!(:dossier) { Timecop.freeze(date_creation) { create(:dossier, :with_entreprise, :en_construction, procedure: procedure) } }
      let(:body) { JSON.parse(retour.body, symbolize_names: true) }

      it 'return REST code 200', :show_in_doc do
        expect(retour.code).to eq('200')
      end

      it { expect(body).to have_key :pagination }

      it { expect(body).to have_key :dossiers }

      describe 'pagination' do
        subject { body[:pagination] }
        it { is_expected.to have_key(:page) }
        it { expect(subject[:page]).to eq(1) }
        it { is_expected.to have_key(:resultats_par_page) }
        it { expect(subject[:resultats_par_page]).to eq(12) }
        it { is_expected.to have_key(:nombre_de_page) }
        it { expect(subject[:nombre_de_page]).to eq(1) }
      end

      describe 'dossiers' do
        subject { body[:dossiers] }
        it { expect(subject).to be_an(Array) }
        describe 'dossier' do
          subject { super().first }
          it { expect(subject[:id]).to eq(dossier.id) }
          it { expect(subject[:updated_at]).to eq("2008-09-01T10:05:00.000Z") }
          it { expect(subject[:initiated_at]).to eq("2008-09-01T10:06:00.000Z") }
          it { expect(subject.keys.size).to eq(3) }
        end
      end

      context 'when there are multiple pages' do
        let(:retour) { get :index, params: { token: admin.api_token, procedure_id: procedure_id, page: 2 } }

        let!(:dossier1) { create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction') }
        let!(:dossier2) { create(:dossier, :with_entreprise, procedure: procedure, state: 'en_construction') }

        before do
          allow(controller).to receive(:per_page).and_return(1)
        end

        describe 'pagination' do
          subject { body[:pagination] }

          it { expect(subject[:page]).to eq(2) }
          it { expect(subject[:resultats_par_page]).to eq(1) }
          it { expect(subject[:nombre_de_page]).to eq(3) }
        end
      end
    end
  end

  describe 'GET show' do
    let(:retour) { get :show, params: { token: admin.api_token, procedure_id: procedure_id, id: dossier_id } }
    subject { retour }

    context 'when procedure is not found' do
      let(:procedure_id) { 99_999_999 }
      let(:dossier_id) { 1 }
      it { expect(subject.code).to eq('404') }
    end

    context 'when procedure exists and does not belong to current admin' do
      let(:procedure_id) { wrong_procedure.id }
      let(:dossier_id) { 1 }
      it { expect(subject.code).to eq('404') }
    end

    context 'when procedure is found and belongs to current admin' do
      context 'when dossier does not exist' do
        let(:procedure_id) { procedure.id }
        let(:dossier_id) { 99999 }
        it { expect(subject.code).to eq('404') }
      end

      context 'when dossier exists but does not belong to procedure' do
        let(:procedure_id) { procedure.id }
        let(:dossier) { create(:dossier, :with_entreprise, procedure: wrong_procedure) }
        let(:dossier_id) { dossier.id }
        it { expect(subject.code).to eq('404') }
      end

      context 'when dossier exists and belongs to procedure' do
        let(:procedure_id) { procedure.id }
        let(:date_creation) { Time.utc(2008, 9, 1, 10, 5, 0) }
        let!(:dossier) { Timecop.freeze(date_creation) { create(:dossier, :with_entreprise, procedure: procedure, motivation: "Motivation") } }
        let(:dossier_id) { dossier.id }
        let(:body) { JSON.parse(retour.body, symbolize_names: true) }
        let(:field_list) { [:id, :created_at, :updated_at, :archived, :mandataire_social, :individual, :entreprise, :etablissement, :cerfa, :types_de_piece_justificative, :pieces_justificatives, :champs, :champs_private, :commentaires, :state, :simplified_state, :initiated_at, :processed_at, :received_at, :motivation, :email, :accompagnateurs, :invites] }
        subject { body[:dossier] }

        it 'return REST code 200', :show_in_doc do
          expect(retour.code).to eq('200')
        end

        it { expect(subject[:id]).to eq(dossier.id) }
        it { expect(subject[:state]).to eq(dossier.state) }
        it { expect(subject[:created_at]).to eq('2008-09-01T10:05:00.000Z') }
        it { expect(subject[:updated_at]).to eq('2008-09-01T10:05:00.000Z') }
        it { expect(subject[:archived]).to eq(dossier.archived) }
        it { expect(subject[:mandataire_social]).to eq(dossier.mandataire_social) }

        it { expect(subject.keys).to match_array(field_list) }

        describe 'entreprise' do
          let(:field_list) {
            [
              :siren,
              :capital_social,
              :numero_tva_intracommunautaire,
              :forme_juridique,
              :forme_juridique_code,
              :nom_commercial,
              :raison_sociale,
              :siret_siege_social,
              :code_effectif_entreprise,
              :date_creation,
              :nom,
              :prenom
            ]
          }
          subject { super()[:entreprise] }

          it { expect(subject[:siren]).to eq('440117620') }
          it { expect(subject[:capital_social]).to eq(537_100_000) }
          it { expect(subject[:numero_tva_intracommunautaire]).to eq('FR27440117620') }
          it { expect(subject[:forme_juridique]).to eq('SA à conseil d\'administration (s.a.i.)') }
          it { expect(subject[:forme_juridique_code]).to eq('5599') }
          it { expect(subject[:nom_commercial]).to eq('GRTGAZ') }
          it { expect(subject[:raison_sociale]).to eq('GRTGAZ') }
          it { expect(subject[:siret_siege_social]).to eq('44011762001530') }
          it { expect(subject[:code_effectif_entreprise]).to eq('51') }
          it { expect(subject[:date_creation]).to eq('2016-01-28T10:16:29.000Z') }
          it { expect(subject.keys).to match_array(field_list) }
        end

        describe 'types_de_piece_justificative' do
          let(:field_list) { [:id, :libelle, :description] }
          subject { super()[:types_de_piece_justificative] }

          it { expect(subject.length).to eq 2 }

          describe 'first type de piece justificative' do
            subject { super().first }

            it { expect(subject.keys.include?(:id)).to be_truthy }
            it { expect(subject[:libelle]).to eq('RIB') }
            it { expect(subject[:description]).to eq('Releve identité bancaire') }
          end
        end

        describe 'piece justificative', vcr: { cassette_name: 'controllers_api_v1_dossiers_controller_piece_justificative' } do
          before do
            create :piece_justificative, :rib, dossier: dossier, type_de_piece_justificative: dossier.procedure.types_de_piece_justificative.first, user: dossier.user
          end

          let(:field_list) { [:url, :created_at, :type_de_piece_justificative_id] }
          subject { super()[:pieces_justificatives].first }

          it { expect(subject.keys.include?(:content_url)).to be_truthy }
          it { expect(subject[:created_at]).not_to be_nil }
          it { expect(subject[:type_de_piece_justificative_id]).not_to be_nil }

          it { expect(subject.keys.include?(:user)).to be_truthy }

          describe 'user' do
            subject { super()[:user] }

            it { expect(subject[:email]).not_to be_nil }
          end
        end

        describe 'champs' do
          let(:field_list) { [:url] }
          subject { super()[:champs] }

          it { expect(subject.length).to eq 1 }

          describe 'first champs' do
            subject { super().first }

            it { expect(subject.keys.include?(:value)).to be_truthy }
            it { expect(subject.keys.include?(:type_de_champ)).to be_truthy }

            describe 'type de champ' do
              let(:field_list) {
                [
                  :id,
                  :libelle,
                  :description,
                  :order_place,
                  :type
                ]
              }
              subject { super()[:type_de_champ] }

              it { expect(subject.keys.include?(:id)).to be_truthy }
              it { expect(subject[:libelle]).to include('Libelle du champ') }
              it { expect(subject[:description]).to include('description du champ') }
              it { expect(subject.keys.include?(:order_place)).to be_truthy }
              it { expect(subject[:type_champ]).to eq('text') }
            end
          end

          context 'when the dossier includes a quartier prioritaire' do
            before do
              dossier.quartier_prioritaires << create(:quartier_prioritaire)
            end

            subject do
              super().find { |champ| champ[:type_de_champ][:type_champ] == 'quartier_prioritaire' }
            end

            it { expect(subject[:type_de_champ]).to match({ id: -1, libelle: 'quartier prioritaire', type_champ: 'quartier_prioritaire', order_place: -1, descripton: '' }) }
            it { expect(subject[:value]).to match(dossier.quartier_prioritaires.first.geometry.symbolize_keys) }
          end

          context 'when the dossier includes a cadastre' do
            before do
              dossier.cadastres << create(:cadastre)
            end

            subject do
              super().find { |champ| champ[:type_de_champ][:type_champ] == 'cadastre' }
            end

            it { expect(subject[:type_de_champ]).to match({ id: -1, libelle: 'cadastre', type_champ: 'cadastre', order_place: -1, descripton: '' }) }
            it { expect(subject[:value]).to match(dossier.cadastres.first.geometry.symbolize_keys) }
          end

          context 'when the dossier includes some user geometry' do
            before do
              dossier.json_latlngs = '[[{"lat": 2.0, "lng": 102.0}, {"lat": 3.0, "lng": 103.0}, {"lat": 2.0, "lng": 102.0}]]'
              dossier.save
            end

            subject do
              super().find { |champ| champ[:type_de_champ][:type_champ] == 'user_geometry' }
            end

            it { expect(subject[:type_de_champ]).to match({ id: -1, libelle: 'user_geometry', type_champ: 'user_geometry', order_place: -1, descripton: '' }) }
            it { expect(subject[:value]).to match(UserGeometry.new(dossier.json_latlngs).value) }
          end
        end

        describe 'champs_private' do
          let(:field_list) { [:url] }
          subject { super()[:champs_private] }

          it { expect(subject.length).to eq 1 }

          describe 'first champs' do
            subject { super().first }

            it { expect(subject.keys.include?(:value)).to be_truthy }
            it { expect(subject.keys.include?(:type_de_champ)).to be_truthy }

            describe 'type de champ' do
              let(:field_list) {
                [
                  :id,
                  :libelle,
                  :description,
                  :order_place,
                  :type
                ]
              }
              subject { super()[:type_de_champ] }

              it { expect(subject.keys.include?(:id)).to be_truthy }
              it { expect(subject[:libelle]).to include('Libelle champ privé') }
              it { expect(subject[:description]).to include('description du champ privé') }
              it { expect(subject.keys.include?(:order_place)).to be_truthy }
              it { expect(subject[:type_champ]).to eq('text') }
            end
          end
        end

        describe 'commentaires' do
          let!(:commentaire) { create :commentaire, body: 'plop', created_at: '2016-03-14 14:00:00', email: 'plop@plip.com', dossier: dossier }
          let!(:commentaire_2) { create :commentaire, body: 'plip', created_at: '2016-03-14 15:00:00', email: 'plip@plap.com', dossier: dossier }

          subject { super()[:commentaires] }

          it { expect(subject.size).to eq 2 }

          it { expect(subject.first[:body]).to eq 'plop' }
          it { expect(subject.first[:created_at]).to eq '2016-03-14T14:00:00.000Z' }
          it { expect(subject.first[:email]).to eq 'plop@plip.com' }
        end

        describe 'cerfa', vcr: { cassette_name: 'controllers_api_v1_dossiers_controller_cerfa' } do
          let!(:dossier) { Timecop.freeze(date_creation) { create(:dossier, :with_entreprise, :with_cerfa_upload, procedure: procedure) } }
          let(:content) { File.open('./spec/support/files/piece_justificative_388.pdf') }

          before do
            tmp_cerfa = dossier.cerfa.first
            tmp_cerfa.content = content
            tmp_cerfa.user = dossier.user
            tmp_cerfa.save
          end

          subject { super()[:cerfa].first }

          it { expect(subject[:created_at]).not_to be_nil }
          if Features.remote_storage
            it { expect(subject[:content_url]).to match(/^https:\/\/storage.apientreprise.fr\/tps_dev\/cerfa-.*\.pdf$/) }
          else
            it { expect(subject[:content_url]).to match(/^http:\/\/.*downloads.*_CERFA\.pdf$/) }
          end

          describe 'user' do
            let(:field_list) { [:url, :created_at, :type_de_piece_justificative_id] }
            subject { super()[:user] }

            it { expect(subject[:email]).not_to be_nil }
          end
        end

        describe 'etablissement' do
          let(:field_list) {
            [
              :siret,
              :siege_social,
              :naf,
              :libelle_naf,
              :adresse,
              :numero_voie,
              :type_voie,
              :nom_voie,
              :complement_adresse,
              :code_postal,
              :localite,
              :code_insee_localite
            ]
          }
          subject { super()[:etablissement] }

          it { expect(subject[:siret]).to eq('44011762001530') }
          it { expect(subject[:siege_social]).to eq(true) }
          it { expect(subject[:naf]).to eq('4950Z') }
          it { expect(subject[:libelle_naf]).to eq('Transports par conduites') }
          it { expect(subject[:adresse]).to eq("GRTGAZ\r IMMEUBLE BORA\r 6 RUE RAOUL NORDLING\r 92270 BOIS COLOMBES\r") }
          it { expect(subject[:numero_voie]).to eq('6') }
          it { expect(subject[:type_voie]).to eq('RUE') }
          it { expect(subject[:nom_voie]).to eq('RAOUL NORDLING') }
          it { expect(subject[:complement_adresse]).to eq('IMMEUBLE BORA') }
          it { expect(subject[:code_postal]).to eq('92270') }
          it { expect(subject[:localite]).to eq('BOIS COLOMBES') }
          it { expect(subject[:code_insee_localite]).to eq('92009') }
          it { expect(subject.keys).to match_array(field_list) }
        end
      end
    end
  end
end
