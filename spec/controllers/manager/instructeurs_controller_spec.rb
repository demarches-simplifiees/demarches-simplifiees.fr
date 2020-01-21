describe Manager::InstructeursController, type: :controller do
  let(:administration) { create(:administration) }

  describe '#delete' do
    let!(:instructeur) { create(:instructeur) }

    before { sign_in administration }

    subject { delete :delete, params: { id: instructeur.id } }

    it 'deletes the instructeur' do
      subject

      expect(Instructeur.find_by(id: instructeur.id)).to be_nil
    end
  end
end
