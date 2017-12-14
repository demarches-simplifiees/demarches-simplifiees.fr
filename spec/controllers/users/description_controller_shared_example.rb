shared_examples 'description_controller_spec' do
  describe 'GET #show' do
    before do
      dossier.update_column :autorisation_donnees, true
    end
    context 'user is not connected' do
      before do
        sign_out dossier.user
      end

      it 'redirects to users/sign_in' do
        get :show, params: {dossier_id: dossier_id}
        expect(response).to redirect_to('/users/sign_in')
      end
    end

    context 'when all is ok' do
      before do
        dossier.entreprise = create :entreprise
        get :show, params: {dossier_id: dossier_id}
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
      end

      context 'procedure is archived' do
        render_views
        let(:archived_at) { Time.now }

        it { expect(response).to have_http_status(:success) }
        it { expect(response.body).to_not have_content(I18n.t('errors.messages.procedure_archived')) }

        context 'dossier is a draft' do
          let(:state) { 'draft' }

          it { expect(response).to have_http_status(:success) }
          it { expect(response.body).to have_content(I18n.t('errors.messages.procedure_archived')) }
        end
      end
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, params: {dossier_id: bad_dossier_id}

      expect(flash[:alert]).to be_present
      expect(response).to redirect_to(root_path)
    end

    it_behaves_like "not owner of dossier", :show

    describe 'before_action authorized_routes?' do
      context 'when dossier does not have a valid state' do
        before do
          dossier.state = 'received'
          dossier.save

          get :show, params: {dossier_id: dossier.id}
        end

        it { is_expected.to redirect_to root_path }
      end
    end

    describe 'before action check_autorisation_donnees' do
      subject { get :show, params: {dossier_id: dossier_id} }

      context 'when dossier does not have a valid autorisations_donness (nil)' do
        before do
          dossier.update_column :autorisation_donnees, nil
        end

        it { expect(subject).to redirect_to "/users/dossiers/#{dossier.id}" }
      end

      context 'when dossier does not have a valid autorisations_donness (false)' do
        before do
          dossier.update_column :autorisation_donnees, false
        end

        it { expect(subject).to redirect_to "/users/dossiers/#{dossier.id}" }
      end
    end

    describe 'before action check_starter_dossier_informations' do
      subject { get :show, params: {dossier_id: dossier_id} }

      context 'when dossier does not have an enterprise datas' do
        before do
        end

        it { expect(dossier.entreprise).to be_nil }
        it { expect(subject).to redirect_to "/users/dossiers/#{dossier.id}" }
      end

      context 'when dossier does not have an individual datas' do
        before do
          procedure.update_column :for_individual, true
        end

        it { expect(dossier.individual).to be_nil }
        it { expect(subject).to redirect_to "/users/dossiers/#{dossier.id}" }
      end
    end
  end

  describe 'POST #update' do
    let(:timestamp) { Time.now }
    let(:description) { 'Description de test Coucou, je suis un saut à la ligne Je suis un double saut  la ligne.' }

    context 'Tous les attributs sont bons' do
      describe 'Premier enregistrement des données' do
        let(:submit) { {nouveaux: 'nouveaux'} }

        subject { post :update, params: {dossier_id: dossier_id, submit: submit} }

        before do
          dossier.draft!
          subject
          dossier.reload
        end

        it "redirection vers la page recapitulative" do
          expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
        end

        it 'etat du dossier est soumis' do
          expect(dossier.state).to eq('en_construction')
        end

        context 'when user whould like save just a draft' do
          let(:submit) { {brouillon: 'brouillon'} }

          it "redirection vers la page recapitulative" do
            expect(response).to redirect_to("/users/dossiers?liste=brouillon")
          end

          it 'etat du dossier est soumis' do
            expect(dossier.state).to eq('draft')
          end
        end
      end

      context 'En train de manipuler un dossier non brouillon' do
        before do
          dossier.en_construction!
          post :update, params: {dossier_id: dossier_id}
          dossier.reload
        end

        it 'Redirection vers la page récapitulatif' do
          expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
        end

        it 'etat du dossier n\'est pas soumis' do
          expect(dossier.state).not_to eq('draft')
        end
      end
    end

    context 'Quand la procédure accepte les CERFA' do
      subject { post :update, params: {dossier_id: dossier_id,
                                       cerfa_pdf: cerfa_pdf}
      }

      it 'Notification interne is create' do
        expect { subject }.to change(Notification, :count).by (1)
      end

      context 'Sauvegarde du CERFA PDF', vcr: {cassette_name: 'controllers_users_description_controller_save_cerfa'} do
        before do
          post :update, params: {dossier_id: dossier_id,
                                 cerfa_pdf: cerfa_pdf}
          dossier.reload
        end

        context 'when a CERFA PDF is sent', vcr: {cassette_name: 'controllers_users_description_controller_cerfa_is_sent'} do
          subject { dossier.cerfa.first }

          it 'content' do
            if Features.remote_storage
              expect(subject['content']).to eq('cerfa-3dbb3535-5388-4a37-bc2d-778327b9f999.pdf')
            else
              expect(subject['content']).to eq('cerfa.pdf')
            end
          end

          it 'dossier_id' do
            expect(subject.dossier_id).to eq(dossier_id)
          end

          it { expect(subject.user).to eq user }
        end

        context 'les anciens CERFA PDF ne sont pas écrasées' do
          let(:cerfas) { Cerfa.where(dossier_id: dossier_id) }

          before do
            post :update, params: {dossier_id: dossier_id, cerfa_pdf: cerfa_pdf}
          end

          it "il y a deux CERFA PDF pour ce dossier" do
            expect(cerfas.size).to eq 2
          end
        end
      end
    end

    context 'Quand la procédure n\'accepte pas les CERFA' do
      context 'Sauvegarde du CERFA PDF' do
        let!(:procedure) { create(:procedure) }
        before do
          post :update, params: {dossier_id: dossier_id,
                                 cerfa_pdf: cerfa_pdf}
          dossier.reload
        end

        context 'un CERFA PDF est envoyé' do
          it { expect(dossier.cerfa_available?).to be_falsey }
        end
      end
    end

    describe 'Sauvegarde des champs' do
      let(:champs_dossier) { dossier.champs }
      let(:dossier_text_value) { 'test value' }
      let(:dossier_date_value) { '23/06/2016' }
      let(:dossier_hour_value) { '17' }
      let(:dossier_minute_value) { '00' }
      let(:dossier_datetime_champ_id) { dossier.champs.find { |c| c.type_champ == "datetime" }.id }
      let(:dossier_text_champ_id) { dossier.champs.find { |c| c.type_champ == "text" }.id }
      let(:params) {
        {
          dossier_id: dossier_id,
          champs: {
            "'#{dossier_text_champ_id}'" => dossier_text_value, # PARFOIS ce putain de champ est associé à un type datetime, et en plus parfois l'ordre n'est pas le bon
            "'#{dossier_datetime_champ_id}'" => dossier_date_value
          },
          time_hour: {
            "'#{dossier_datetime_champ_id}'" => dossier_hour_value,
          },
          time_minute: {
            "'#{dossier_datetime_champ_id}'" => dossier_minute_value,
          }
        }
      }

      before do
        post :update, params: params
        dossier.reload
      end

      it { expect(dossier.champs.find(dossier_text_champ_id).value).to eq(dossier_text_value) }
      it { expect(response).to redirect_to users_dossier_recapitulatif_path }

      context 'when champs is type_de_champ datetime' do
        it { expect(dossier.champs.find(dossier_datetime_champ_id).value).to eq(dossier_date_value + ' ' + dossier_hour_value + ':' + dossier_minute_value) }
      end

      context 'when champs value is empty' do
        let(:dossier_text_value) { '' }

        it { expect(dossier.champs.find(dossier_text_champ_id).value).to eq(dossier_text_value) }
        it { expect(response).to redirect_to users_dossier_recapitulatif_path }

        context 'when champs is mandatory' do
          let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ_mandatory, :with_datetime, cerfa_flag: true) }

          it { expect(response).not_to redirect_to users_dossier_recapitulatif_path }
          it { expect(flash[:alert]).to be_present }
        end
      end
    end

    context 'Sauvegarde des pièces justificatives', vcr: {cassette_name: 'controllers_users_description_controller_sauvegarde_pj'} do
      let(:all_pj_type) { dossier.procedure.type_de_piece_justificative_ids }
      before do
        post :update, params: {dossier_id: dossier_id,
                               'piece_justificative_' + all_pj_type[0].to_s => piece_justificative_0,
                               'piece_justificative_' + all_pj_type[1].to_s => piece_justificative_1}
        dossier.reload
      end

      describe 'clamav anti-virus presence', vcr: {cassette_name: 'controllers_users_description_controller_clamav_presence'} do
        it 'ClamavService safe_file? is call' do
          expect(ClamavService).to receive(:safe_file?).twice

          post :update, params: {dossier_id: dossier_id,
                                 'piece_justificative_' + all_pj_type[0].to_s => piece_justificative_0,
                                 'piece_justificative_' + all_pj_type[1].to_s => piece_justificative_1}
        end
      end

      context 'for piece 0' do
        subject { dossier.retrieve_last_piece_justificative_by_type all_pj_type[0].to_s }
        it { expect(subject.content).not_to be_nil }
        it { expect(subject.user).to eq user }
      end
      context 'for piece 1' do
        subject { dossier.retrieve_last_piece_justificative_by_type all_pj_type[1].to_s }
        it { expect(subject.content).not_to be_nil }
        it { expect(subject.user).to eq user }
      end
    end

    context 'La procédure est archivée' do
      let(:archived_at) { Time.now }

      before do
        post :update, params: { dossier_id: dossier.id }
      end

      it { expect(response.status).to eq(302) }

      context 'Le dossier est en brouillon' do
        let(:state) { 'draft' }

        it { expect(response.status).to eq(403) }
      end
    end
  end

  describe 'POST #pieces_justificatives', vcr: {cassette_name: 'controllers_users_description_controller_pieces_justificatives'} do
    let(:all_pj_type) { dossier.procedure.type_de_piece_justificative_ids }

    subject { patch :pieces_justificatives, params: {dossier_id: dossier.id,
                                                     'piece_justificative_' + all_pj_type[0].to_s => piece_justificative_0,
                                                     'piece_justificative_' + all_pj_type[1].to_s => piece_justificative_1}
    }

    context 'when user is a guest' do
      let(:guest) { create :user }

      before do
        create :invite, dossier: dossier, email: guest.email, user: guest

        sign_in guest
      end

      it 'Notification interne is create' do
        expect { subject }.to change(Notification, :count).by (1)
      end

      context 'when PJ have no documents' do
        it { expect(dossier.pieces_justificatives.size).to eq 0 }

        context 'when upload two PJ' do
          before do
            subject
            dossier.reload
          end

          it { expect(dossier.pieces_justificatives.size).to eq 2 }
          it { expect(flash[:notice]).to be_present }
          it { is_expected.to redirect_to users_dossiers_invite_path(id: guest.invites.find_by_dossier_id(dossier.id).id) }
        end
      end

      context 'when PJ have already a document' do
        before do
          create :piece_justificative, :rib, dossier: dossier, type_de_piece_justificative_id: all_pj_type[0]
          create :piece_justificative, :contrat, dossier: dossier, type_de_piece_justificative_id: all_pj_type[1]
        end

        it { expect(dossier.pieces_justificatives.size).to eq 2 }

        context 'when upload two PJ', vcr: {cassette_name: 'controllers_users_description_controller_upload_2pj'} do
          before do
            subject
            dossier.reload
          end

          it { expect(dossier.pieces_justificatives.size).to eq 4 }
          it { expect(flash[:notice]).to be_present }
          it { is_expected.to redirect_to users_dossiers_invite_path(id: guest.invites.find_by_dossier_id(dossier.id).id) }
        end
      end

      context 'when one of PJs is not valid' do
        let(:piece_justificative_0) { Rack::Test::UploadedFile.new("./spec/support/files/entreprise.json", 'application/json') }

        it { expect(dossier.pieces_justificatives.size).to eq 0 }

        context 'when upload two PJ' do
          before do
            subject
            dossier.reload
          end

          it { expect(dossier.pieces_justificatives.size).to eq 1 }
          it { expect(flash[:alert]).to be_present }
          it { is_expected.to redirect_to users_dossiers_invite_path(id: guest.invites.find_by_dossier_id(dossier.id).id) }
        end
      end
    end
  end
end

shared_examples 'description_controller_spec_POST_piece_justificatives_for_owner' do
  let(:all_pj_type) { dossier.procedure.type_de_piece_justificative_ids }

  subject { patch :pieces_justificatives, params: {dossier_id: dossier.id,
                                                   'piece_justificative_' + all_pj_type[0].to_s => piece_justificative_0,
                                                   'piece_justificative_' + all_pj_type[1].to_s => piece_justificative_1}
  }

  context 'when user is the owner', vcr: {cassette_name: 'controllers_users_description_controller_pieces_justificatives'} do
    before do
      sign_in user
    end

    context 'when PJ have no documents' do
      it { expect(dossier.pieces_justificatives.size).to eq 0 }

      context 'when upload two PJ' do
        before do
          subject
          dossier.reload
        end

        it { expect(dossier.pieces_justificatives.size).to eq 2 }
        it { expect(flash[:notice]).to be_present }
        it { is_expected.to redirect_to recapitulatif_path }
      end
    end

    context 'when PJ have already a document', vcr: {cassette_name: 'controllers_users_description_controller_pj_already_exist'} do
      before do
        create :piece_justificative, :rib, dossier: dossier, type_de_piece_justificative_id: all_pj_type[0]
        create :piece_justificative, :contrat, dossier: dossier, type_de_piece_justificative_id: all_pj_type[1]
      end

      it { expect(dossier.pieces_justificatives.size).to eq 2 }

      context 'when upload two PJ', vcr: {cassette_name: 'controllers_users_description_controller_pj_already_exist_upload_2pj'} do
        before do
          subject
          dossier.reload
        end

        it { expect(dossier.pieces_justificatives.size).to eq 4 }
        it { expect(flash[:notice]).to be_present }
        it { is_expected.to redirect_to recapitulatif_path }
      end
    end

    context 'when one of PJs is not valid' do
      let(:piece_justificative_0) { Rack::Test::UploadedFile.new("./spec/support/files/entreprise.json", 'application/json') }

      it { expect(dossier.pieces_justificatives.size).to eq 0 }

      context 'when upload two PJ' do
        before do
          subject
          dossier.reload
        end

        it { expect(dossier.pieces_justificatives.size).to eq 1 }
        it { expect(flash[:alert]).to be_present }
        it { is_expected.to redirect_to recapitulatif_path }
      end
    end
  end
end
