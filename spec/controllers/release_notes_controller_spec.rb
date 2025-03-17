# frozen_string_literal: true

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

    describe 'touch user announces_seen_at' do
      let(:user) { create(:user, administrateur: build(:administrateur)) }

      context 'when default categories' do
        it 'touch announces_seen_at' do
          expect { subject }.to change { user.reload.announces_seen_at }
        end

        context 'when current announces_seen_at is more recent than last announce' do
          before { user.update(announces_seen_at: 1.second.ago) }

          it 'does not touch announces_seen_at' do
            expect { subject }.not_to change { user.reload.announces_seen_at }
          end
        end
      end

      context 'when specific categories' do
        subject { get :index, params: { categories: ['administrateur', 'instructeur'] } }

        it 'does not touch announces_seen_at' do
          expect { subject }.not_to change { user.reload.announces_seen_at }
        end
      end
    end
  end
end
