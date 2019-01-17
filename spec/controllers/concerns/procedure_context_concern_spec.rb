require 'rails_helper'

RSpec.describe ProcedureContextConcern, type: :controller do
  class TestController < ActionController::Base
    include ProcedureContextConcern

    before_action :restore_procedure_context

    def index
      head :ok
    end
  end

  controller TestController do
  end

  describe '#restore_procedure_context' do
    subject { get :index }

    context 'when no return location has been stored' do
      it 'succeeds, without defining a procedure on the controller' do
        expect(subject.status).to eq 200
        expect(assigns(:procedure)).to be nil
      end
    end

    context 'when no procedure_id is present in the stored return location' do
      before do
        controller.store_location_for(:user, dossiers_path)
      end

      it 'succeeds, without assigns a procedure on the controller' do
        expect(subject.status).to eq 200
        expect(assigns(:procedure)).to be nil
      end
    end

    context 'when a procedure location has been stored' do
      context 'when the stored procedure does not exist' do
        before do
          controller.store_location_for(:user, new_dossier_path(procedure_id: '0'))
        end

        it 'redirects with an error' do
          expect(subject.status).to eq 302
          expect(subject).to redirect_to root_path
        end
      end

      context 'when the stored procedure is not published' do
        let(:procedure) { create :procedure }

        before do
          controller.store_location_for(:user, new_dossier_path(procedure_id: procedure.id))
        end

        it 'redirects with an error' do
          expect(subject.status).to eq 302
          expect(subject).to redirect_to root_path
        end
      end

      context 'when the stored procedure exists' do
        let(:procedure) { create :procedure, :published }

        before do
          controller.store_location_for(:user, new_dossier_path(procedure_id: procedure.id))
        end

        it 'succeeds, and assigns the procedure on the controller' do
          expect(subject.status).to eq 200
          expect(assigns(:procedure)).to eq procedure
        end
      end
    end
  end
end
