require 'spec_helper'

describe Backoffice::ProcedureFilterController, type: :controller do
  let(:gestionnaire) { create :gestionnaire }

  before do
    sign_in gestionnaire
  end

  describe '#GET index' do
    subject { get :index }

    before do
      subject
    end

    it { expect(response.status).to eq 200 }
  end

  describe '#PATCH update' do
    context 'when procedure_filter params is not present' do
      subject { patch :update }

      before do
        subject
      end

      it { is_expected.to redirect_to backoffice_filtres_path }
      it { expect(gestionnaire.procedure_filter).to eq [] }
    end

    context 'when procedure_filter attribut is not empty and procedure_filter params is not present' do
      let(:gestionnaire) { create :gestionnaire, procedure_filter: [3,2] }

      subject { patch :update }

      before do
        subject
        gestionnaire.reload
      end

      it { is_expected.to redirect_to backoffice_filtres_path }
      it { expect(gestionnaire.procedure_filter).to eq [] }
    end

    context 'when procedure_filter params is present' do
      let (:procedure_filter) { ["3", "1"] }

      subject { patch :update, procedure_filter: procedure_filter }

      before do
        subject
        gestionnaire.reload
      end

      it { is_expected.to redirect_to backoffice_filtres_path }
      it { expect(gestionnaire.procedure_filter.size).to eq 2 }
      it { expect(gestionnaire.procedure_filter).to include 1 }
      it { expect(gestionnaire.procedure_filter).to include 3 }
    end
  end
end
