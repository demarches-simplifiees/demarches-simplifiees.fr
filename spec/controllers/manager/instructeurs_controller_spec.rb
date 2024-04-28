# frozen_string_literal: true

describe Manager::InstructeursController, type: :controller do
  let(:super_admin) { create(:super_admin) }
  let(:instructeur) { create(:instructeur) }

  describe '#show' do
    render_views

    before do
      sign_in(super_admin)
      get :show, params: { id: instructeur.id }
    end

    it { expect(response.body).to include(instructeur.email) }
  end

  describe '#delete' do
    before { sign_in super_admin }

    subject { delete :delete, params: { id: instructeur.id } }

    it 'deletes the instructeur' do
      subject

      expect(Instructeur.find_by(id: instructeur.id)).to be_nil
    end
  end
end
