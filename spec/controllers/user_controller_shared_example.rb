shared_examples 'current_user_dossier_spec' do
  context 'when no dossier_id is filled' do
    it { expect { subject.current_user_dossier }.to raise_error }
  end

  context 'when dossier_id is given as a param' do
    context 'when dossier id is valid' do
      it 'returns current user dossier' do
        expect(subject.current_user_dossier dossier.id).to eq(dossier)
      end
    end

    context 'when dossier id is incorrect' do
      it { expect { subject.current_user_dossier 1 }.to raise_error }
    end
  end

  context 'when no params[] is given' do
    context 'when dossier id is valid' do
      before do
        subject.params[:dossier_id] = dossier.id
      end

      it 'returns current user dossier' do
        expect(subject.current_user_dossier).to eq(dossier)
      end
    end

    context 'when dossier id is incorrect' do
      it { expect { subject.current_user_dossier }.to raise_error }
    end

    context 'when dossier_id is given as a param' do
      before do
        subject.params[:dossier_id] = 1
      end

      it 'returns dossier with the id on params past' do
        expect(subject.current_user_dossier dossier.id).to eq(dossier)
      end
    end
  end
end
