require 'spec_helper'

describe StartController, type: :controller do
  let!(:procedure) { create(:procedure) }

  describe 'GET #index' do
    before do
      get :index, procedure_id: procedure
    end

    context 'when params procedure_id is present' do
      context 'when procedure_id is valid' do
        context 'when user is logged in' do
          before do
            sign_in create(:user)
          end
          subject { get :index, procedure_id: procedure }
          it { expect(subject).to have_http_status(:success) }
          context 'when procedure_id is not valid' do
            let(:procedure) { '' }
            it { is_expected.to have_http_status(404) }
          end
          context 'when params procedure_id is not present' do
            subject { get :index }
            it { is_expected.to have_http_status(404) }
          end
        end
        context 'when user is not logged' do
          it { expect(response).to have_http_status(302) }
        end
      end
    end
  end

  # describe 'GET #index with bad SIRET' do
  #   before do
  #     get :error_siret, procedure_id: procedure
  #   end

  #   it 'returns http success and flash alert is present' do
  #     expect(response).to have_http_status(:success)
  #   end
  #   it 'la flash alert est présente' do
  #     expect(flash[:alert]).to be_present
  #   end
  #   it 'la flash alert a un libellé correct' do
  #     expect(flash[:alert]).to have_content('Ce SIRET n\'est pas valide')
  #   end
  # end

  # describe 'GET #index with bad LOGIN' do
  #   before do
  #     get :error_login
  #   end

  #   it 'returns http success and flash alert is present' do
  #     expect(response).to have_http_status(:success)
  #   end
  #   it 'la flash alert est présente' do
  #     expect(flash[:alert]).to be_present
  #   end
  #   it 'la flash alert a un libellé correct' do
  #     expect(flash[:alert]).to have_content('Ce compte n\'existe pas')
  #   end
  # end

  # describe 'GET #index with bad DOSSIER' do
  #   before do
  #     get :error_dossier
  #   end

  #   it 'returns http success and flash alert is present' do
  #     expect(response).to have_http_status(:success)
  #   end
  #   it 'la flash alert est présente' do
  #     expect(flash[:alert]).to be_present
  #   end
  #   it 'la flash alert a un libellé correct' do
  #     expect(flash[:alert]).to have_content('Ce dossier n\'existe pas')
  #   end
  # end
end
