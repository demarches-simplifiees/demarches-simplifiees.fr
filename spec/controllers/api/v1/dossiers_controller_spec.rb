require 'spec_helper'

describe API::V1::DossiersController do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, administrateur: admin) }
  let(:wrong_procedure) { create(:procedure) }

  it { expect(described_class).to be < APIController }

  describe 'GET index' do
    let(:response) { get :index, token: admin.api_token, procedure_id: procedure_id }

    subject { response }

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
      let(:date_creation) { Time.local(2008, 9, 1, 10, 5, 0) }
      let!(:dossier) { Timecop.freeze(date_creation) { create(:dossier, :with_entreprise, procedure: procedure, state: 'initiated') } }
      let(:body) { JSON.parse(response.body, symbolize_names: true) }

      it 'return REST code 200', :show_in_doc do
        expect(response.code).to eq('200')
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
          it { expect(subject[:nom_projet]).to eq(dossier.nom_projet) }
          it { expect(subject[:updated_at]).to eq("2008-09-01T08:05:00.000Z") }
          it { expect(subject.keys.size).to eq(3) }
        end
      end

      context 'when there are multiple pages' do
        let(:response) { get :index, token: admin.api_token, procedure_id: procedure_id, page: 2 }

        let!(:dossier1) { create(:dossier, :with_entreprise, procedure: procedure, state: 'initiated') }
        let!(:dossier2) { create(:dossier, :with_entreprise, procedure: procedure, state: 'initiated') }

        before do
          allow(Dossier).to receive(:per_page).and_return(1)
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
    let(:response) { get :show, token: admin.api_token, procedure_id: procedure_id, id: dossier_id }
    subject { response }

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
        let(:date_creation) { Time.local(2008, 9, 1, 10, 5, 0) }
        let!(:dossier) { Timecop.freeze(date_creation) { create(:dossier, :with_entreprise, procedure: procedure) } }
        let(:dossier_id) { dossier.id }
        let(:body) { JSON.parse(response.body, symbolize_names: true) }
        let(:field_list) { [:id, :nom_projet, :created_at, :updated_at, :description, :archived, :mandataire_social, :entreprise, :etablissement, :cerfa, :pieces_justificatives, :champs] }
        subject { body[:dossier] }

        it 'return REST code 200', :show_in_doc do
          expect(response.code).to eq('200')
        end
        it { expect(subject[:id]).to eq(dossier.id) }
        it { expect(subject[:nom_projet]).to eq(dossier.nom_projet) }
        it { expect(subject[:created_at]).to eq('2008-09-01T08:05:00.000Z') }
        it { expect(subject[:updated_at]).to eq('2008-09-01T08:05:00.000Z') }
        it { expect(subject[:description]).to eq(dossier.description) }
        it { expect(subject[:archived]).to eq(dossier.archived) }
        it { expect(subject[:mandataire_social]).to eq(dossier.mandataire_social) }

        it { expect(subject.keys).to match_array(field_list) }

        describe 'entreprise' do
          let(:field_list) { [
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
              :prenom] }
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

        describe 'pieces_justificatives' do
          let(:field_list) { [
              :url] }
          subject { super()[:pieces_justificatives] }

          it { expect(subject.length).to eq 2 }

          describe 'first piece justificative' do
            subject { super().first }

            it { expect(subject.keys.include?(:url)).to be_truthy }
            it { expect(subject.keys.include?(:type_de_piece_justificative)).to be_truthy }

            describe 'type de piece justificative' do
              let(:field_list) { [
                  :id,
                  :libelle,
                  :description] }
              subject { super()[:type_de_piece_justificative] }

              it { expect(subject.keys.include?(:id)).to be_truthy }
              it { expect(subject[:libelle]).to eq('RIB') }
              it { expect(subject[:description]).to eq('Releve identité bancaire') }
            end
          end
        end

        describe 'champs' do
          let(:field_list) { [
              :url] }
          subject { super()[:champs] }

          it { expect(subject.length).to eq 1 }

          describe 'first champs' do
            subject { super().first }

            it { expect(subject.keys.include?(:value)).to be_truthy }
            it { expect(subject.keys.include?(:type_de_champ)).to be_truthy }

            describe 'type de champ' do
              let(:field_list) { [
                  :id,
                  :libelle,
                  :description,
                  :order_place,
                  :type] }
              subject { super()[:type_de_champ] }

              it { expect(subject.keys.include?(:id)).to be_truthy }
              it { expect(subject[:libelle]).to eq('Description') }
              it { expect(subject[:description]).to eq('description de votre projet') }
              it { expect(subject.keys.include?(:order_place)).to be_truthy }
              it { expect(subject[:type]).to eq('textarea') }
            end
          end
        end

        describe 'etablissement' do
          let(:field_list) { [
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
          ] }
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
