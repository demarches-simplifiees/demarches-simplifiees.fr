require 'spec_helper'

describe UsersController, type: :controller do

  describe '.current_user_dossier' do
    let(:user) { create(:user) }
    let(:dossier) { create(:dossier, user: user)}

    before do
      sign_in user
    end

    context 'when no params table exist and no params past at the function' do
      it { expect{ subject.current_user_dossier }.to raise_error }
    end

    context 'when no params table exist and params past at the function' do
      context 'when dossier id is good' do
        it 'returns current user dossier' do
          expect(subject.current_user_dossier dossier.id).to eq(dossier)
        end
      end

      context 'when dossier id is bad' do
        it { expect{ subject.current_user_dossier 1 }.to raise_error }
      end
    end

    context 'when params table exist and no params past at the function' do
      context 'when dossier id is good' do
        before do
          subject.params[:dossier_id] = dossier.id
        end

        it 'returns current user dossier' do
          expect(subject.current_user_dossier).to eq(dossier)
        end
      end

      context 'when dossier id is bad' do
        it { expect{ subject.current_user_dossier }.to raise_error }
      end
    end

    context 'when params table exist and params past at the function' do
      before do
        subject.params[:dossier_id] = 1
      end

      it 'returns dossier with the id on params past' do
        expect(subject.current_user_dossier dossier.id).to eq(dossier)
      end
    end
  end
end