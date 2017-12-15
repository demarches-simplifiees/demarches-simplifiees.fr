require 'spec_helper'

describe Backoffice::Dossiers::ProcedureController, type: :controller do
  let(:gestionnaire) { create :gestionnaire }
  let(:procedure) { create :procedure, :published }
  let(:archived) { false }
  let(:dossier) { create :dossier, procedure: procedure, archived: archived, state: 'en_construction'}

  before do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure
    sign_in gestionnaire
    gestionnaire.build_default_preferences_list_dossier procedure.id
  end

  describe 'GET #index' do
    let(:procedure_id) { procedure.id }

    subject { get :index, params: {id: procedure_id} }

    it { expect(subject.status).to eq 200 }

    context 'when procedure id is not found' do
      let(:procedure_id) { 100000 }

      before do
        subject
      end

      it { expect(response.status).to eq 302 }
      it { is_expected.to redirect_to backoffice_dossiers_path }
      it { expect(flash[:alert]).to be_present}
    end

    context 'when procedure contains a dossier' do
      render_views

      before do
        dossier
        subject
      end

      it { expect(response.body).to have_content('Tous les dossiers 1 dossier') }

      context 'archived' do
        let(:archived) { true }

        it { expect(response.body).to have_content('Tous les dossiers 0 dossiers') }
        it { expect(response.body).to have_content('Dossiers archivés 1 dossier') }
      end
    end
  end

  describe 'GET #filter' do
    subject { get :filter, params: {id: procedure.id, filter_input: {"entreprise.raison_sociale" => "plop"}} }

    it { is_expected.to redirect_to backoffice_dossiers_procedure_path(id: procedure.id) }
  end
end
