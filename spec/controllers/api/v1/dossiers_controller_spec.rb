require 'spec_helper'

describe API::V1::DossiersController do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, administrateur: admin) }
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
      let!(:dossier) { Timecop.freeze(date_creation) { create(:dossier, :with_entreprise, procedure: procedure) } }
      let(:body) { JSON.parse(response.body, symbolize_names: true) }
      it { expect(response.code).to eq('200') }
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
        let!(:dossier1) { create(:dossier, :with_entreprise, procedure: procedure) }
        let!(:dossier2) { create(:dossier, :with_entreprise, procedure: procedure) }
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
end
