describe Champs::OptionsController, type: :controller do
  let(:user) { create(:user) }
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :multiple_drop_down_list }]) }

  describe '#remove' do
    let(:dossier) { create(:dossier, user:, procedure:) }
    let(:champ) { dossier.champs.first }

    before {
      sign_in user
      champ.update(value: ['toto', 'tata'].to_json)
    }

    context 'with stable_id' do
      subject { delete :remove, params: { dossier_id: dossier, stable_id: champ.stable_id, option: 'tata' }, format: :turbo_stream }

      it 'remove option' do
        expect { subject }.to change { champ.reload.selected_options.size }.from(2).to(1)
      end
    end

    context 'with champ_id' do
      subject { delete :remove, params: { champ_id: champ.id, option: 'tata' }, format: :turbo_stream }

      it 'remove option' do
        expect { subject }.to change { champ.reload.selected_options.size }.from(2).to(1)
      end
    end
  end
end
