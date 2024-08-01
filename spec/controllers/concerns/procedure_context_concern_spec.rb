# frozen_string_literal: true

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

    context 'when the stored return location is not a procedure URL' do
      before do
        controller.store_location_for(:user, dossiers_path)
      end

      it 'succeeds, without assigns a procedure on the controller' do
        expect(subject.status).to eq 200
        expect(assigns(:procedure)).to be nil
      end
    end

    context 'when a procedure location has been stored' do
      context 'when the procedure path does not exist' do
        before do
          controller.store_location_for(:user, commencer_path(path: 'non-existent-path'))
        end

        it 'redirects with an error' do
          expect(subject.status).to eq 302
          expect(subject).to redirect_to root_path
        end
      end

      context 'when the stored procedure is in test' do
        let(:test_procedure) { create :procedure, :with_path }

        before do
          controller.store_location_for(:user, commencer_path(path: test_procedure.path))
        end

        it 'succeeds, and assigns the procedure on the controller' do
          expect(subject.status).to eq 200
          expect(assigns(:procedure)).to eq test_procedure
        end

        context 'when a prefill token has been stored' do
          let(:dossier) { create :dossier, :prefilled, procedure: test_procedure }

          before do
            controller.store_location_for(:user, commencer_path(path: test_procedure.path, prefill_token: dossier.prefill_token))
          end

          it 'succeeds, and assigns the prefill token on the controller' do
            expect(subject.status).to eq 200
            expect(assigns(:prefill_token)).to eq dossier.prefill_token
          end
        end
      end

      context 'when the stored procedure is published' do
        let(:published_procedure) { create :procedure, :published }

        before do
          controller.store_location_for(:user, commencer_path(path: published_procedure.path))
        end

        it 'succeeds, and assigns the procedure on the controller' do
          expect(subject.status).to eq 200
          expect(assigns(:procedure)).to eq published_procedure
        end

        context 'when a prefill token has been stored' do
          let(:dossier) { create :dossier, :prefilled, procedure: published_procedure }

          before do
            controller.store_location_for(:user, commencer_path(path: published_procedure.path, prefill_token: dossier.prefill_token))
          end

          it 'succeeds, and assigns the prefill token on the controller' do
            expect(subject.status).to eq 200
            expect(assigns(:prefill_token)).to eq dossier.prefill_token
          end
        end
      end
    end
  end
end
