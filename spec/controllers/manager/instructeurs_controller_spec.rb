describe Manager::InstructeursController, type: :controller do
  let(:administration) { create(:administration) }
  let(:instructeur) { create(:instructeur) }

  describe '#show' do
    render_views

    before do
      sign_in(administration)
      get :show, params: { id: instructeur.id }
    end

    it { expect(response.body).to include(instructeur.email) }
  end

  describe '#delete' do
    before { sign_in administration }

    subject { delete :delete, params: { id: instructeur.id } }

    it 'deletes the instructeur' do
      subject

      expect(Instructeur.find_by(id: instructeur.id)).to be_nil
    end
  end
end
