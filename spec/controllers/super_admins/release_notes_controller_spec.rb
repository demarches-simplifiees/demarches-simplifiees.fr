require 'rails_helper'

describe SuperAdmins::ReleaseNotesController, type: :controller do
  let(:super_admin) { create(:super_admin) }

  before do
    sign_in super_admin if super_admin.present?
  end

  describe "acl" do
    context 'when user is not signed as super admin' do
      let(:super_admin) { nil }
      let!(:release_note) { create(:release_note, published: false) }

      it 'is not allowed to post' do
        expect { post :create, params: { release_note: { released_on: Date.current, published: "0", body: "bam" } } }.not_to change(ReleaseNote, :count)
        expect(response.status).to eq(302)
        expect(flash[:alert]).to be_present
      end

      it 'is not allowed to put' do
        expect {
          put :update, params: {
            id: release_note.id,
            release_note: {
              released_on: Date.current,
              published: "1",
              categories: release_note.categories,
              body: "hacked body"
            }
          }
        }.not_to change { release_note.reload.body }
        expect(response.status).to eq(302)
        expect(flash[:alert]).to be_present
      end

      it 'is not allowed to index' do
        get :index
        expect(response.status).to eq(302)
        expect(flash[:alert]).to be_present
      end
    end

    context 'when user is signed as super admin' do
      it 'is allowed to post' do
        expect { post :create, params: { release_note: { categories: ['api'], released_on: Date.current, published: "0", body: "bam" } } }.to change(ReleaseNote, :count).by(1)
        expect(flash[:notice]).to be_present
      end

      it 'is allowed to put' do
        release_note = create(:release_note, published: false)
        put :update, params: {
          id: release_note.id,
          release_note: {
            released_on: Date.current,
            published: "1",
            categories: release_note.categories,
            body: "new body"
          }
        }

        release_note.reload
        expect(release_note.body.to_plain_text).to eq("new body")
        expect(release_note.published).to be_truthy
      end
    end
  end
end
