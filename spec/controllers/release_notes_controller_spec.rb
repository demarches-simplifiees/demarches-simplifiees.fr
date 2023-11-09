require 'rails_helper'

RSpec.describe ReleaseNotesController, type: :controller do
  let!(:note_admin) { create(:release_note, categories: ['administrateur'], body: "Pour l'admin", released_on: Date.new(2023, 10, 15)) }
  let!(:note_instructeur) { create(:release_note, categories: ['instructeur'], body: "Pour l'instructeur", released_on: Date.new(2023, 10, 13)) }

  let(:user) { nil }
  let(:admin) { create(:user, administrateur: build(:administrateur)) }
  let(:instructeur) { create(:user, instructeur: build(:instructeur)) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET index' do
    subject { get :index }

    describe 'filtering' do
      before { subject }
      context 'user is admininistrateur' do
        let(:user) { admin }
        it { is_expected.to have_http_status(:ok) }
        it { expect(assigns(:announces)).to eq([note_admin]) }
      end

      context 'user is instructeur' do
        let(:user) { instructeur }
        it { is_expected.to have_http_status(:ok) }
        it { expect(assigns(:announces)).to eq([note_instructeur]) }
      end

      context 'user is expert' do
        let(:user) { create(:user, expert: build(:expert)) }
        it { expect(assigns(:announces)).to eq([]) }
      end
    end

    describe 'acl' do
      before { subject }
      context 'user is normal' do
        let(:user) { create(:user) }

        it { is_expected.to be_redirection }
      end

      context 'no user' do
        it { is_expected.to be_redirection }
      end
    end
  end
end
