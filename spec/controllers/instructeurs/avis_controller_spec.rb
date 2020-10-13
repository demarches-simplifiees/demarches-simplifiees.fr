describe Instructeurs::AvisController, type: :controller do
  context 'with a instructeur signed in' do
    render_views

    let(:now) { Time.zone.parse('01/02/2345') }
    let(:claimant) { create(:instructeur) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, :published, instructeurs: [claimant]) }
    let(:another_procedure) { create(:procedure, :published, instructeurs: [claimant]) }
    let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
    let!(:avis_without_answer) { Avis.create(dossier: dossier, claimant: claimant, instructeur: instructeur) }
    let!(:avis_with_answer) { Avis.create(dossier: dossier, claimant: claimant, instructeur: instructeur, answer: 'yop') }

    before { sign_in(instructeur.user) }

    describe '#index' do
      before { get :index }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis_by_procedure).flatten).to include(procedure) }
      it { expect(assigns(:avis_by_procedure).flatten).not_to include(another_procedure) }
    end

    describe '#procedure' do
      before { get :procedure, params: { procedure_id: procedure.id } }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis_a_donner)).to match([avis_without_answer]) }
      it { expect(assigns(:avis_donnes)).to match([avis_with_answer]) }
      it { expect(assigns(:statut)).to eq('a-donner') }

      context 'with a statut equal to donnes' do
        before { get :procedure, params: { statut: 'donnes', procedure_id: procedure.id } }

        it { expect(assigns(:statut)).to eq('donnes') }
      end
    end

    describe '#show' do
      subject { get :show, params: { id: avis_with_answer.id, procedure_id: procedure.id } }

      context 'with a valid avis' do
        before { subject }

        it { expect(response).to have_http_status(:success) }
        it { expect(assigns(:avis)).to eq(avis_with_answer) }
        it { expect(assigns(:dossier)).to eq(dossier) }
      end

      context 'with a revoked avis' do
        it "refuse l'accès au dossier" do
          avis_with_answer.update!(revoked_at: Time.zone.now)
          subject
          expect(flash.alert).to eq("Vous n'avez plus accès à ce dossier.")
          expect(response).to redirect_to(root_path)
        end
      end
    end

    describe '#instruction' do
      before { get :instruction, params: { id: avis_without_answer.id, procedure_id: procedure.id } }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis)).to eq(avis_without_answer) }
      it { expect(assigns(:dossier)).to eq(dossier) }
    end

    describe '#messagerie' do
      before { get :messagerie, params: { id: avis_without_answer.id, procedure_id: procedure.id } }

      it { expect(response).to have_http_status(:success) }
      it { expect(assigns(:avis)).to eq(avis_without_answer) }
      it { expect(assigns(:dossier)).to eq(dossier) }
    end

    describe '#bilans_bdf' do
      before { get :bilans_bdf, params: { id: avis_without_answer.id, procedure_id: procedure.id } }

      it { expect(response).to redirect_to(instructeur_avis_path(avis_without_answer)) }
    end

    describe '#update' do
      context 'without attachment' do
        before do
          Timecop.freeze(now)
          patch :update, params: { id: avis_without_answer.id, procedure_id: procedure.id, avis: { answer: 'answer' } }
          avis_without_answer.reload
        end
        after { Timecop.return }

        it 'should be ok' do
          expect(response).to redirect_to(instruction_instructeur_avis_path(avis_without_answer.procedure, avis_without_answer))
          expect(avis_without_answer.answer).to eq('answer')
          expect(avis_without_answer.piece_justificative_file).to_not be_attached
          expect(dossier.reload.last_avis_updated_at).to eq(now)
          expect(flash.notice).to eq('Votre réponse est enregistrée.')
        end
      end

      context 'with attachment' do
        include ActiveJob::TestHelper
        let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

        before do
          expect(ClamavService).to receive(:safe_file?).and_return(true)
          perform_enqueued_jobs do
            post :update, params: { id: avis_without_answer.id, procedure_id: procedure.id, avis: { answer: 'answer', piece_justificative_file: file } }
          end
          avis_without_answer.reload
        end

        it 'should be ok' do
          expect(response).to redirect_to(instruction_instructeur_avis_path(avis_without_answer.procedure, avis_without_answer))
          expect(avis_without_answer.answer).to eq('answer')
          expect(avis_without_answer.piece_justificative_file).to be_attached
          expect(flash.notice).to eq('Votre réponse est enregistrée.')
        end
      end
    end

    describe '#create_commentaire' do
      let(:file) { nil }
      let(:scan_result) { true }
      let(:now) { Time.zone.parse("14/07/1789") }

      subject { post :create_commentaire, params: { id: avis_without_answer.id, procedure_id: procedure.id, commentaire: { body: 'commentaire body', piece_jointe: file } } }

      before do
        allow(ClamavService).to receive(:safe_file?).and_return(scan_result)
        Timecop.freeze(now)
      end

      after { Timecop.return }

      it do
        subject

        expect(response).to redirect_to(messagerie_instructeur_avis_path(avis_without_answer.procedure, avis_without_answer))
        expect(dossier.commentaires.map(&:body)).to match(['commentaire body'])
        expect(dossier.reload.last_commentaire_updated_at).to eq(now)
      end

      context "with a file" do
        let(:file) { fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf') }

        it do
          subject
          expect(Commentaire.last.piece_jointe.filename).to eq("piece_justificative_0.pdf")
        end

        it { expect { subject }.to change(Commentaire, :count).by(1) }
      end
    end

    describe '#expert_cannot_invite_another_expert' do
      let!(:previous_avis) { Avis.create(dossier: dossier, claimant: claimant, instructeur: instructeur, confidentiel: previous_avis_confidentiel) }
      let(:previous_avis_confidentiel) { false }
      let(:asked_confidentiel) { false }
      let(:intro) { 'introduction' }
      let(:emails) { ["toto@totomail.com"] }
      let(:invite_linked_dossiers) { nil }

      before do
        Flipper.enable_actor(:expert_not_allowed_to_invite, procedure)
        post :create_avis, params: { id: previous_avis.id, procedure_id: procedure.id, avis: { emails: emails, introduction: intro, confidentiel: asked_confidentiel, invite_linked_dossiers: invite_linked_dossiers, introduction_file: @introduction_file } }
      end

      context 'when the expert cannot invite another expert' do
        let(:asked_confidentiel) { false }
        it { expect(flash.alert).to eq("Cette démarche ne vous permet pas de demander un avis externe") }
        it { expect(response).to redirect_to(instruction_instructeur_avis_path(procedure, previous_avis)) }
      end
    end

    describe '#create_avis' do
      let!(:previous_avis) { Avis.create(dossier: dossier, claimant: claimant, instructeur: instructeur, confidentiel: previous_avis_confidentiel) }
      let(:emails) { ['a@b.com'] }
      let(:intro) { 'introduction' }
      let(:created_avis) { Avis.last }
      let!(:old_avis_count) { Avis.count }
      let(:invite_linked_dossiers) { nil }

      before do
        Timecop.freeze(now)
        @introduction_file = fixture_file_upload('spec/fixtures/files/piece_justificative_0.pdf', 'application/pdf')
        post :create_avis, params: { id: previous_avis.id, procedure_id: procedure.id, avis: { emails: emails, introduction: intro, confidentiel: asked_confidentiel, invite_linked_dossiers: invite_linked_dossiers, introduction_file: @introduction_file } }
        created_avis.reload
      end
      after { Timecop.return }

      context 'when an invalid email' do
        let(:previous_avis_confidentiel) { false }
        let(:asked_confidentiel) { false }
        let(:emails) { ["toto.fr"] }

        it { expect(response).to render_template :instruction }
        it { expect(flash.alert).to eq(["toto.fr : Email n'est pas valide"]) }
        it { expect(Avis.last).to eq(previous_avis) }
        it { expect(dossier.last_avis_updated_at).to eq(nil) }
      end

      context 'ask review with attachment' do
        let(:previous_avis_confidentiel) { false }
        let(:asked_confidentiel) { false }
        let(:emails) { ["toto@totomail.com"] }

        it { expect(created_avis.introduction_file).to be_attached }
        it { expect(created_avis.introduction_file.filename).to eq("piece_justificative_0.pdf") }
        it { expect(created_avis.dossier.reload.last_avis_updated_at).to eq(now) }
        it { expect(flash.notice).to eq("Une demande d'avis a été envoyée à toto@totomail.com") }
      end

      context 'with multiple emails' do
        let(:asked_confidentiel) { false }
        let(:previous_avis_confidentiel) { false }
        let(:emails) { ["toto.fr,titi@titimail.com"] }

        it { expect(response).to render_template :instruction }
        it { expect(flash.alert).to eq(["toto.fr : Email n'est pas valide"]) }
        it { expect(flash.notice).to eq("Une demande d'avis a été envoyée à titi@titimail.com") }
        it { expect(Avis.count).to eq(old_avis_count + 1) }
        it { expect(created_avis.email).to eq("titi@titimail.com") }
      end

      context 'when the previous avis is public' do
        let(:previous_avis_confidentiel) { false }

        context 'when the user asked for a public avis' do
          let(:asked_confidentiel) { false }

          it { expect(created_avis.confidentiel).to be(false) }
          it { expect(created_avis.email).to eq(emails.last) }
          it { expect(created_avis.introduction).to eq(intro) }
          it { expect(created_avis.dossier).to eq(previous_avis.dossier) }
          it { expect(created_avis.claimant).to eq(instructeur) }
          it { expect(response).to redirect_to(instruction_instructeur_avis_path(previous_avis.procedure, previous_avis)) }
        end

        context 'when the user asked for a confidentiel avis' do
          let(:asked_confidentiel) { true }

          it { expect(created_avis.confidentiel).to be(true) }
        end
      end

      context 'when the preivous avis is confidentiel' do
        let(:previous_avis_confidentiel) { true }

        context 'when the user asked for a public avis' do
          let(:asked_confidentiel) { false }

          it { expect(created_avis.confidentiel).to be(true) }
        end
      end

      context 'with linked dossiers' do
        let(:asked_confidentiel) { false }
        let(:previous_avis_confidentiel) { false }
        let(:dossier) { create(:dossier, :en_construction, :with_dossier_link, procedure: procedure) }

        context 'when the expert doesn’t share linked dossiers' do
          let(:invite_linked_dossiers) { false }

          it 'sends a single avis for the main dossier, but doesn’t give access to the linked dossiers' do
            expect(flash.notice).to eq("Une demande d'avis a été envoyée à a@b.com")
            expect(Avis.count).to eq(old_avis_count + 1)
            expect(created_avis.email).to eq("a@b.com")
            expect(created_avis.dossier).to eq(dossier)
          end
        end

        context 'when the expert also shares the linked dossiers' do
          let(:invite_linked_dossiers) { true }

          context 'and the expert can access the linked dossiers' do
            let(:created_avis) { Avis.last(2).first }
            let(:linked_avis) { Avis.last }
            let(:linked_dossier) { Dossier.find_by(id: dossier.reload.champs.filter(&:dossier_link?).map(&:value).compact) }
            let(:invite_linked_dossiers) do
              instructeur.assign_to_procedure(linked_dossier.procedure)
              true
            end

            it 'sends one avis for the main dossier' do
              expect(flash.notice).to eq("Une demande d'avis a été envoyée à a@b.com")
              expect(created_avis.email).to eq("a@b.com")
              expect(created_avis.dossier).to eq(dossier)
            end

            it 'sends another avis for the linked dossiers' do
              expect(Avis.count).to eq(old_avis_count + 2)
              expect(linked_avis.dossier).to eq(linked_dossier)
            end
          end

          context 'but the expert can’t access the linked dossier' do
            it 'sends a single avis for the main dossier, but doesn’t give access to the linked dossiers' do
              expect(flash.notice).to eq("Une demande d'avis a été envoyée à a@b.com")
              expect(Avis.count).to eq(old_avis_count + 1)
              expect(created_avis.email).to eq("a@b.com")
              expect(created_avis.dossier).to eq(dossier)
            end
          end
        end
      end
    end

    describe "#revoker" do
      let(:avis) { create(:avis, claimant: instructeur) }
      let(:procedure) { avis.procedure }

      it "revoke the dossier" do
        patch :revoquer, params: { procedure_id: procedure.id, id: avis.id }

        expect(flash.notice).to eq("#{avis.email} ne peut plus donner son avis sur ce dossier.")
      end
    end

    describe 'revive' do
      let(:avis) { create(:avis, claimant: instructeur, email: 'expert@gouv.fr') }
      let(:procedure) { avis.procedure }

      before do
        allow(AvisMailer).to receive(:avis_invitation).and_return(double(deliver_later: nil))
      end

      it 'sends a reminder to the expert' do
        get :revive, params: { procedure_id: procedure.id, id: avis.id }
        expect(AvisMailer).to have_received(:avis_invitation).once.with(avis)
        expect(flash.notice).to eq("Un mail de relance a été envoyé à #{avis.email}")
      end
    end
  end

  context 'without a instructeur signed in' do
    describe '#sign_up' do
      let(:invited_email) { 'invited@avis.com' }
      let(:dossier) { create(:dossier) }
      let(:procedure) { dossier.procedure }
      let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }
      let(:invitations_email) { true }

      context 'when the new instructeur has never signed up' do
        before do
          expect(Avis).to receive(:avis_exists_and_email_belongs_to_avis?)
            .with(avis.id.to_s, invited_email)
            .and_return(invitations_email)
          get :sign_up, params: { id: avis.id, procedure_id: procedure.id, email: invited_email }
        end

        context 'when the email belongs to the invitation' do
          it { expect(subject.status).to eq(200) }
          it { expect(assigns(:email)).to eq(invited_email) }
          it { expect(assigns(:dossier)).to eq(dossier) }
        end

        context 'when the email does not belong to the invitation' do
          let(:invitations_email) { false }

          it { is_expected.to redirect_to root_path }
        end
      end

      context 'when the instructeur has already signed up and belongs to the invitation' do
        let(:instructeur) { create(:instructeur, email: invited_email) }
        let!(:avis) { create(:avis, dossier: dossier, instructeur: instructeur) }

        context 'when the instructeur is authenticated' do
          before do
            sign_in(instructeur.user)
            get :sign_up, params: { id: avis.id, procedure_id: procedure.id, email: invited_email }
          end

          it { is_expected.to redirect_to instructeur_avis_url(avis.procedure, avis) }
        end

        context 'when the instructeur is not authenticated' do
          before do
            get :sign_up, params: { id: avis.id, procedure_id: procedure.id, email: invited_email }
          end

          it { is_expected.to redirect_to new_user_session_url }
        end
      end

      context 'when the instructeur has already signed up / is authenticated and does not belong to the invitation' do
        let(:instructeur) { create(:instructeur, email: 'other@gmail.com') }
        let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }

        before do
          sign_in(instructeur.user)
          get :sign_up, params: { id: avis.id, procedure_id: procedure.id, email: invited_email }
        end

        # redirected to dossier but then the instructeur gonna be banished !
        it { is_expected.to redirect_to instructeur_avis_url(avis.procedure, avis) }
      end
    end

    describe '#create_instructeur' do
      let(:existing_user_mail) { 'dummy@example.org' }
      let!(:existing_user) { create(:user, email: existing_user_mail) }
      let(:invited_email) { 'invited@avis.com' }
      let(:dossier) { create(:dossier) }
      let(:procedure) { dossier.procedure }
      let!(:avis) { create(:avis, email: invited_email, dossier: dossier) }
      let(:avis_id) { avis.id }
      let(:password) { TEST_PASSWORD }
      let(:created_instructeur) { Instructeur.by_email(invited_email) }
      let(:invitations_email) { true }

      before do
        allow(Avis).to receive(:link_avis_to_instructeur)
        expect(Avis).to receive(:avis_exists_and_email_belongs_to_avis?)
          .with(avis_id.to_s, invited_email)
          .and_return(invitations_email)

        post :create_instructeur, params: {
          id: avis_id,
          procedure_id: procedure.id,
          email: invited_email,
          user: {
            password: password
          }
        }
      end

      context 'when the email does not belong to the invitation' do
        let(:invitations_email) { false }

        it { is_expected.to redirect_to root_path }
      end

      context 'when the email belongs to the invitation' do
        context 'when the instructeur creation succeeds' do
          it { expect(created_instructeur).to be_present }
          it { expect(created_instructeur.user.valid_password?(password)).to be true }

          it { expect(Avis).to have_received(:link_avis_to_instructeur) }

          it { expect(subject.current_instructeur).to eq(created_instructeur) }
          it { is_expected.to redirect_to instructeur_all_avis_path }

          it 'creates a corresponding user account for the email' do
            user = User.find_by(email: invited_email)
            expect(user).to be_present
          end

          context 'when there already is a user account with the same email' do
            let(:existing_user_mail) { invited_email }

            it 'still creates a instructeur account' do
              expect(created_instructeur).to be_present
            end
          end
        end

        context 'when the instructeur creation fails' do
          let(:password) { '' }

          it { expect(created_instructeur).to be_nil }
          it { is_expected.to redirect_to sign_up_instructeur_avis_path(procedure.id, avis_id, invited_email) }
          it { expect(flash.alert).to eq(['Le mot de passe doit être rempli']) }
        end
      end
    end
  end
end
