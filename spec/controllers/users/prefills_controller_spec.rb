describe Users::PrefillsController, type: :controller do
  describe '#show' do
    let(:dossier) { create(:dossier, :brouillon, :prefilled, user: user) }
    subject(:show_request) { get :show, params: { id: dossier.id, token: dossier.prefill_token } }

    shared_examples 'a prefilled brouillon dossier retriever' do
      context 'when the dossier is a prefilled brouillon and the prefill token is present' do
        it 'retrieves the dossier' do
          show_request
          expect(assigns(:dossier)).to eq(dossier)
        end
      end

      context 'when the dossier is not prefilled' do
        before do
          dossier.prefilled = false
          dossier.save(validate: false)
        end

        it { expect { show_request }.to raise_error(ActiveRecord::RecordNotFound) }
      end

      context 'when the dossier is not a brouillon' do
        before { dossier.en_construction! }

        it { expect { show_request }.to raise_error(ActiveRecord::RecordNotFound) }
      end

      context 'when the prefill token does not match' do
        before { dossier.prefill_token = "totoro" }

        it { expect { show_request }.to raise_error(ActiveRecord::RecordNotFound) }
      end

      context 'when the prefill token is missing' do
        before { dossier.prefill_token = "" }

        it { expect { show_request }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    end

    context 'when the user is unauthenticated' do
      let(:user) { nil }

      it_behaves_like 'a prefilled brouillon dossier retriever'
    end

    context 'when the user is authenticated' do
      context 'when the dossier already has an owner' do
        let(:user) { create(:user) }

        context 'when the user is the dossier owner' do
          before { sign_in user }

          it_behaves_like 'a prefilled brouillon dossier retriever'

          it { expect(show_request).to redirect_to(brouillon_dossier_path(dossier)) }
        end

        context 'when the user is not the dossier owner' do
          before { sign_in create(:user) }

          it { expect { show_request }.to raise_error(ActiveRecord::RecordNotFound) }
        end
      end

      context 'when the dossier does not have an owner yet' do
        let(:user) { nil }
        let(:newly_authenticated_user) { create(:user) }

        before { sign_in newly_authenticated_user }

        it { expect(show_request).to redirect_to(brouillon_dossier_path(dossier)) }

        it { expect { show_request }.to change { dossier.reload.user }.from(nil).to(newly_authenticated_user) }
      end
    end
  end
end
