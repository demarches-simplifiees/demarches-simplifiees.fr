describe PrefillDescriptionsController, type: :controller do
  describe '#edit' do
    subject(:edit_request) do
      get :edit, params: { path: procedure.path }
    end

    context 'when the procedure is found' do
      context 'when the procedure is publiee' do
        context 'when the procedure is opendata' do
          let(:procedure) { create(:procedure, :published, opendata: true) }

          it { expect(edit_request).to render_template(:edit) }
        end

        context 'when the procedure is not opendata' do
          let(:procedure) { create(:procedure, :published, opendata: false) }

          it { expect { edit_request }.to raise_error(ActiveRecord::RecordNotFound) }
        end
      end

      context 'when the procedure is brouillon' do
        context 'when the procedure is opendata' do
          let(:procedure) { create(:procedure, :draft, opendata: true) }

          it { expect(edit_request).to render_template(:edit) }
        end

        context 'when the procedure is not opendata' do
          let(:procedure) { create(:procedure, :draft, opendata: false) }

          it { expect { edit_request }.to raise_error(ActiveRecord::RecordNotFound) }
        end
      end

      context 'when the procedure is not publiee and not brouillon' do
        let(:procedure) { create(:procedure, :closed) }

        it { expect { edit_request }.to raise_error(ActiveRecord::RecordNotFound) }
      end
    end

    context 'when the procedure is not found' do
      let(:procedure) { double(Procedure, path: "wrong path") }

      it { expect { edit_request }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe "#update" do
    render_views

    let(:procedure) { create(:procedure, :published, opendata: true) }
    let(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }
    let(:type_de_champ2) { create(:type_de_champ_text, procedure: procedure) }

    subject(:update_request) do
      patch :update, params: { path: procedure.path, procedure: params }, format: :turbo_stream
    end

    before { update_request }

    context 'when adding a type_de_champ_id' do
      let(:type_de_champ_to_add) { create(:type_de_champ_text, procedure: procedure) }
      let(:params) { { selected_type_de_champ_ids: [type_de_champ.id, type_de_champ_to_add.id] } }

      it { expect(response).to render_template(:update) }

      it "includes the prefill URL" do
        expect(response.body).to include(commencer_path(path: procedure.path))
        expect(response.body).to include({ "champ_#{type_de_champ.to_typed_id}" => type_de_champ.libelle }.to_query)
        expect(response.body).to include({ "champ_#{type_de_champ_to_add.to_typed_id}" => type_de_champ_to_add.libelle }.to_query)
      end
    end

    context 'when removing a type_de_champ_id' do
      let(:type_de_champ_to_remove) { type_de_champ2 }
      let(:params) { { selected_type_de_champ_ids: [type_de_champ] } }

      it { expect(response).to render_template(:update) }

      it "includes the prefill URL" do
        expect(response.body).to include(commencer_path(path: procedure.path))
        expect(response.body).to include({ "champ_#{type_de_champ.to_typed_id}" => type_de_champ.libelle }.to_query)
        expect(response.body).not_to include({ "champ_#{type_de_champ_to_remove.to_typed_id}" => type_de_champ_to_remove.libelle }.to_query)
      end
    end

    context 'when removing the last type de champ' do
      let(:type_de_champ_to_remove) { type_de_champ }
      let(:params) { { selected_type_de_champ_ids: [] } }

      it { expect(response).to render_template(:update) }

      it "does not include the prefill URL" do
        expect(response.body).not_to include(commencer_path(path: procedure.path))
      end
    end
  end
end
