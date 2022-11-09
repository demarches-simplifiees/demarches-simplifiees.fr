describe Instructeurs::ProceduresController, type: :controller do
  describe "before_action: ensure_ownership!" do
    it "is present" do
      before_actions = Instructeurs::ProceduresController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:ensure_ownership!)
    end
  end

  describe "ensure_ownership!" do
    let(:instructeur) { create(:instructeur) }

    before do
      @controller.params = @controller.params.merge(procedure_id: asked_procedure.id)
      expect(@controller).to receive(:current_instructeur).and_return(instructeur)
      allow(@controller).to receive(:redirect_to)

      @controller.send(:ensure_ownership!)
    end

    context "when a instructeur asks for its procedure" do
      let(:asked_procedure) { create(:procedure, instructeurs: [instructeur]) }

      it "does not redirects nor flash" do
        expect(@controller).not_to have_received(:redirect_to)
        expect(flash.alert).to eq(nil)
      end
    end

    context "when a instructeur asks for another procedure" do
      let(:asked_procedure) { create(:procedure) }

      it "redirects and flash" do
        expect(@controller).to have_received(:redirect_to).with(root_path)
        expect(flash.alert).to eq("Vous n’avez pas accès à cette démarche")
      end
    end
  end

  describe "#index" do
    let(:instructeur) { create(:instructeur) }
    subject { get :index }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before { sign_in(instructeur.user) }

      it { expect(response).to have_http_status(:ok) }

      context "with procedures assigned" do
        let(:procedure_draft) { create(:procedure) }
        let(:procedure_published) { create(:procedure, :published) }
        let(:procedure_closed) { create(:procedure, :closed) }
        let(:procedure_draft_discarded) { create(:procedure, :discarded) }
        let(:procedure_closed_discarded) { create(:procedure, :discarded) }
        let(:procedure_not_assigned) { create(:procedure) }

        before do
          [procedure_draft, procedure_published, procedure_closed, procedure_draft_discarded, procedure_closed_discarded].each do |p|
            instructeur.groupe_instructeurs << p.defaut_groupe_instructeur
          end
          subject
        end

        it 'assigns procedures visible to the instructeur' do
          expect(assigns(:procedures)).to include(procedure_draft, procedure_published, procedure_closed)
          expect(assigns(:procedures)).not_to include(procedure_draft_discarded, procedure_closed_discarded, procedure_not_assigned)
        end
      end

      context "with dossiers" do
        let(:procedure) { create(:procedure, :published, :expirable) }
        let(:dossier) { create(:dossier, state: state, procedure: procedure) }

        before do
          instructeur.groupe_instructeurs << procedure.defaut_groupe_instructeur
          dossier
        end

        context "with brouillon state" do
          let(:state) { Dossier.states.fetch(:brouillon) }
          before { subject }

          it { expect(assigns(:dossiers_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_expirant_count_per_procedure)[procedure.id]).to eq(nil) }

          it { expect(assigns(:all_dossiers_counts)['à suivre']).to eq(0) }
          it { expect(assigns(:all_dossiers_counts)['suivis']).to eq(0) }
          it { expect(assigns(:all_dossiers_counts)['traités']).to eq(0) }
          it { expect(assigns(:all_dossiers_counts)['dossiers']).to eq(0) }
          it { expect(assigns(:all_dossiers_counts)['archivés']).to eq(0) }
          it { expect(assigns(:all_dossiers_counts)['expirant']).to eq(0) }
        end

        context "with not draft state on multiple procedures" do
          let(:procedure2) { create(:procedure, :published, :expirable) }
          let(:state) { Dossier.states.fetch(:en_construction) }

          before do
            create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction))
            create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), hidden_by_user_at: 1.hour.ago)
            create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction))

            create(:dossier, procedure: procedure, state: Dossier.states.fetch(:sans_suite), archived: true)
            create(:dossier, procedure: procedure, state: Dossier.states.fetch(:sans_suite), archived: true,
                             hidden_by_administration_at: 1.day.ago)

            instructeur.groupe_instructeurs << procedure2.defaut_groupe_instructeur
            create(:dossier, :followed, procedure: procedure2, state: Dossier.states.fetch(:en_construction))
            create(:dossier, procedure: procedure2, state: Dossier.states.fetch(:accepte))
            instructeur.followed_dossiers << create(:dossier, procedure: procedure2, state: Dossier.states.fetch(:en_instruction))

            create(:dossier, procedure: procedure,
                             state: Dossier.states.fetch(:sans_suite),
                             processed_at: 8.months.ago) # counted as expirable
            create(:dossier, procedure: procedure,
                             state: Dossier.states.fetch(:sans_suite),
                             processed_at: 8.months.ago,
                             hidden_by_administration_at: 1.day.ago) # not counted as expirable since its removed by instructeur
            create(:dossier, procedure: procedure,
                             state: Dossier.states.fetch(:sans_suite),
                             processed_at: 8.months.ago,
                             hidden_by_user_at: 1.day.ago) # counted as expirable because even if user remove it, instructeur see it
            subject
          end

          it { expect(assigns(:dossiers_count_per_procedure)[procedure.id]).to eq(5) }
          it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure.id]).to eq(3) }
          it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure.id]).to eq(1) }
          it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure.id]).to eq(2) }
          it { expect(assigns(:dossiers_expirant_count_per_procedure)[procedure.id]).to eq(2) }

          it { expect(assigns(:dossiers_count_per_procedure)[procedure2.id]).to eq(3) }
          it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure2.id]).to eq(nil) }
          it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure2.id]).to eq(1) }
          it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure2.id]).to eq(nil) }
          it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure2.id]).to eq(1) }

          it { expect(assigns(:all_dossiers_counts)['à suivre']).to eq(3 + 0) }
          it { expect(assigns(:all_dossiers_counts)['suivis']).to eq(0 + 1) }
          it { expect(assigns(:all_dossiers_counts)['traités']).to eq(2 + 1) }
          it { expect(assigns(:all_dossiers_counts)['dossiers']).to eq(5 + 3) }
          it { expect(assigns(:all_dossiers_counts)['archivés']).to eq(1 + 0) }
          it { expect(assigns(:all_dossiers_counts)['expirant']).to eq(2 + 0) }
        end

        context 'with not draft state on discarded procedure' do
          let(:discarded_procedure) { create(:procedure, :discarded, :expirable) }
          let(:state) { Dossier.states.fetch(:en_construction) }
          before do
            create(:dossier, procedure: discarded_procedure, state: Dossier.states.fetch(:en_construction))
            instructeur.groupe_instructeurs << discarded_procedure.defaut_groupe_instructeur
            subject
          end

          it { expect(assigns(:dossiers_count_per_procedure)[procedure.id]).to eq(1) }
          it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure.id]).to eq(1) }

          it { expect(assigns(:dossiers_count_per_procedure)[discarded_procedure.id]).to be_nil }

          it { expect(assigns(:all_dossiers_counts)['à suivre']).to eq(1) }
        end
      end

      context "with a routed procedure" do
        let!(:procedure) { create(:procedure, :published) }
        let!(:gi_p1_1) { procedure.defaut_groupe_instructeur }
        let!(:gi_p1_2) { GroupeInstructeur.create(label: '2', procedure: procedure) }

        context 'with multiple dossiers en construction on each group' do
          before do
            alternate_gis = 0.upto(20).map { |i| i.even? ? gi_p1_1 : gi_p1_2 }

            alternate_gis.take(4).each { |gi| create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_construction), groupe_instructeur: gi) }

            alternate_gis.take(6).each do |gi|
              instructeur.followed_dossiers << create(:dossier, procedure: procedure, state: Dossier.states.fetch(:en_instruction), groupe_instructeur: gi)
            end

            alternate_gis.take(10).each { |gi| create(:dossier, procedure: procedure, state: Dossier.states.fetch(:sans_suite), groupe_instructeur: gi) }
            alternate_gis.take(14).each { |gi| create(:dossier, procedure: procedure, state: Dossier.states.fetch(:sans_suite), archived: true, groupe_instructeur: gi) }
          end

          context 'when an instructeur belongs to the 2 gi' do
            before do
              instructeur.groupe_instructeurs << gi_p1_1 << gi_p1_2

              subject
            end

            it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure.id]).to eq(4) }
            it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure.id]).to eq(6) }
            it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure.id]).to eq(10) }
            it { expect(assigns(:dossiers_count_per_procedure)[procedure.id]).to eq(4 + 6 + 10) }
            it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure.id]).to eq(14) }

            it { expect(assigns(:all_dossiers_counts)['à suivre']).to eq(4) }
            it { expect(assigns(:all_dossiers_counts)['suivis']).to eq(6) }
            it { expect(assigns(:all_dossiers_counts)['traités']).to eq(10) }
            it { expect(assigns(:all_dossiers_counts)['dossiers']).to eq(4 + 6 + 10) }
            it { expect(assigns(:all_dossiers_counts)['archivés']).to eq(14) }
          end

          context 'when an instructeur only belongs to one of them gi' do
            before do
              instructeur.groupe_instructeurs << gi_p1_1

              subject
            end

            it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure.id]).to eq(2) }
            # An instructeur cannot follow a dossier which belongs to another groupe
            it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure.id]).to eq(3) }
            it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure.id]).to eq(5) }
            it { expect(assigns(:dossiers_count_per_procedure)[procedure.id]).to eq(2 + 3 + 5) }
            it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure.id]).to eq(7) }

            it { expect(assigns(:all_dossiers_counts)['à suivre']).to eq(2) }
            it { expect(assigns(:all_dossiers_counts)['suivis']).to eq(3) }
            it { expect(assigns(:all_dossiers_counts)['traités']).to eq(5) }
            it { expect(assigns(:all_dossiers_counts)['dossiers']).to eq(2 + 3 + 5) }
            it { expect(assigns(:all_dossiers_counts)['archivés']).to eq(7) }
          end
        end
      end
    end
  end

  describe "#show" do
    let(:instructeur) { create(:instructeur) }
    let!(:procedure) { create(:procedure, :expirable, instructeurs: [instructeur]) }
    let!(:gi_2) { procedure.groupe_instructeurs.create(label: '2') }
    let!(:gi_3) { procedure.groupe_instructeurs.create(label: '3') }
    let(:statut) { nil }

    subject do
      get :show, params: { procedure_id: procedure.id, statut: statut }
    end

    context "when logged in, and belonging to gi_1, gi_2" do
      before do
        sign_in(instructeur.user)
        instructeur.groupe_instructeurs << gi_2
      end

      context 'when the procedure is discarded' do
        before do
          procedure.discard!
        end

        it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
      end

      context "without any dossier" do
        before { subject }

        it { expect(response).to have_http_status(:ok) }
        it { expect(assigns(:procedure)).to eq(procedure) }
      end

      context 'with a new dossier without follower' do
        let!(:new_unfollow_dossier) { create(:dossier, :en_instruction, procedure: procedure) }

        context do
          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([new_unfollow_dossier].map(&:id)) }
        end

        context 'with a dossier en contruction hidden by user' do
          let!(:hidden_dossier) { create(:dossier, :en_construction, groupe_instructeur: gi_2, hidden_by_user_at: 1.hour.ago) }
          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([new_unfollow_dossier].map(&:id)) }
        end

        context 'with a dossier en contruction not hidden by user' do
          let!(:en_construction_dossier) { create(:dossier, :en_construction, groupe_instructeur: gi_2) }
          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([new_unfollow_dossier, en_construction_dossier].map(&:id)) }
        end

        context 'and dossiers without follower on each of the others groups' do
          let!(:new_unfollow_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2) }
          let!(:new_unfollow_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3) }

          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([new_unfollow_dossier, new_unfollow_dossier_on_gi_2].map(&:id)) }
        end
      end

      context 'with a new dossier with a follower' do
        let(:statut) { 'suivis' }
        let!(:new_followed_dossier) { create(:dossier, :en_instruction, procedure: procedure, followers_instructeurs: [instructeur]) }

        context do
          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([new_followed_dossier].map(&:id)) }
        end

        context 'and dossier with a follower on each of the others groups' do
          let!(:new_follow_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2, followers_instructeurs: [instructeur]) }
          let!(:new_follow_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3, followers_instructeurs: [instructeur]) }

          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([new_followed_dossier, new_follow_dossier_on_gi_2].map(&:id)) }
        end
      end

      context 'with a termine dossier with a follower' do
        let(:statut) { 'traites' }
        let!(:termine_dossier) { create(:dossier, :accepte, procedure: procedure) }

        context do
          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([termine_dossier].map(&:id)) }
        end

        context 'and terminer dossiers on each of the others groups' do
          let!(:termine_dossier_on_gi_2) { create(:dossier, :accepte, groupe_instructeur: gi_2) }
          let!(:termine_dossier_on_gi_3) { create(:dossier, :accepte, groupe_instructeur: gi_3) }

          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([termine_dossier, termine_dossier_on_gi_2].map(&:id)) }
        end
      end

      context 'with an archived dossier' do
        let(:statut) { 'archives' }
        let!(:archived_dossier) { create(:dossier, :en_instruction, procedure: procedure, archived: true) }
        let!(:archived_dossier_deleted) { create(:dossier, :en_instruction, procedure: procedure, archived: true, hidden_by_administration_at: 2.days.ago) }

        context do
          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([archived_dossier].map(&:id)) }
        end

        context 'and terminer dossiers on each of the others groups' do
          let!(:archived_dossier_on_gi_2) { create(:dossier, :en_instruction, groupe_instructeur: gi_2, archived: true) }
          let!(:archived_dossier_on_gi_3) { create(:dossier, :en_instruction, groupe_instructeur: gi_3, archived: true) }

          before { subject }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([archived_dossier, archived_dossier_on_gi_2].map(&:id)) }
        end
      end

      context 'with an expirants dossier' do
        let(:statut) { 'expirant' }
        let!(:expiring_dossier_termine_deleted) { create(:dossier, :accepte, procedure: procedure, processed_at: 175.days.ago, hidden_by_administration_at: 2.days.ago) }
        let!(:expiring_dossier_termine) { create(:dossier, :accepte, procedure: procedure, processed_at: 175.days.ago) }
        let!(:expiring_dossier_en_construction) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: 175.days.ago) }

        before { subject }

        it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([expiring_dossier_termine, expiring_dossier_en_construction].map(&:id)) }
      end

      describe 'statut' do
        let!(:a_suivre_dossier) { Timecop.freeze(1.day.ago) { create(:dossier, :en_instruction, procedure: procedure) } }
        let!(:new_followed_dossier) { Timecop.freeze(2.days.ago) { create(:dossier, :en_instruction, procedure: procedure) } }
        let!(:termine_dossier) { Timecop.freeze(3.days.ago) { create(:dossier, :accepte, procedure: procedure) } }
        let!(:archived_dossier) { Timecop.freeze(4.days.ago) { create(:dossier, :en_instruction, procedure: procedure, archived: true) } }

        before do
          instructeur.followed_dossiers << new_followed_dossier
          subject
        end

        context 'when statut is empty' do
          let(:statut) { nil }

          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([a_suivre_dossier].map(&:id)) }
          it { expect(assigns(:statut)).to eq('a-suivre') }
        end

        context 'when statut is a-suivre' do
          let(:statut) { 'a-suivre' }

          it { expect(assigns(:statut)).to eq('a-suivre') }
          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([a_suivre_dossier].map(&:id)) }
        end

        context 'when statut is suivis' do
          let(:statut) { 'suivis' }

          it { expect(assigns(:statut)).to eq('suivis') }
          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([new_followed_dossier].map(&:id)) }
        end

        context 'when statut is traites' do
          let(:statut) { 'traites' }

          it { expect(assigns(:statut)).to eq('traites') }
          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([termine_dossier].map(&:id)) }
        end

        context 'when statut is tous' do
          let(:statut) { 'tous' }

          it { expect(assigns(:statut)).to eq('tous') }
          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([a_suivre_dossier, new_followed_dossier, termine_dossier].map(&:id)) }
        end

        context 'when statut is archives' do
          let(:statut) { 'archives' }

          it { expect(assigns(:statut)).to eq('archives') }
          it { expect(assigns(:filtered_sorted_paginated_ids)).to match_array([archived_dossier].map(&:id)) }
        end
      end
    end
  end

  describe '#deleted_dossiers' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure, instructeurs: [instructeur]) }
    let(:deleted_dossier) { create(:deleted_dossier, procedure: procedure, state: :en_construction) }

    before do
      sign_in(instructeur.user)
      get :deleted_dossiers, params: { procedure_id: procedure.id }
    end

    it { expect(assigns(:deleted_dossiers)).to match_array([deleted_dossier]) }
  end

  describe '#update_email_notifications' do
    let(:instructeur) { create(:instructeur) }
    let!(:procedure) { create(:procedure, instructeurs: [instructeur]) }

    context "when logged in" do
      before { sign_in(instructeur.user) }

      it { expect(instructeur.groupe_instructeur_with_email_notifications).to be_empty }

      context 'when the instructeur update its preferences' do
        let(:assign_to) { instructeur.assign_to.joins(:groupe_instructeur).find_by(groupe_instructeurs: { procedure: procedure }) }

        before do
          patch :update_email_notifications, params: { procedure_id: procedure.id, assign_to: { id: assign_to.id, daily_email_notifications_enabled: true } }
        end

        it { expect(instructeur.groupe_instructeur_with_email_notifications).to eq([procedure.defaut_groupe_instructeur]) }
      end
    end
  end

  describe '#download_export' do
    let(:instructeur) { create(:instructeur) }
    let!(:procedure) { create(:procedure) }
    let!(:assign_to) { create(:assign_to, instructeur: instructeur, groupe_instructeur: build(:groupe_instructeur, procedure: procedure), manager: manager) }
    let!(:gi_0) { assign_to.groupe_instructeur }
    let!(:gi_1) { create(:groupe_instructeur, label: 'gi_1', procedure: procedure, instructeurs: [instructeur]) }
    let(:manager) { false }
    before { sign_in(instructeur.user) }

    subject do
      get :download_export, params: { export_format: :csv, procedure_id: procedure.id }
    end

    context 'when the export is does not exist' do
      it 'displays an notice' do
        is_expected.to redirect_to(instructeur_procedure_url(procedure))
        expect(flash.notice).to be_present
      end

      it { expect { subject }.to change(Export, :count).by(1) }
    end

    context 'when the export is not ready' do
      before do
        create(:export, groupe_instructeurs: [gi_1])
      end

      it 'displays an notice' do
        is_expected.to redirect_to(instructeur_procedure_url(procedure))
        expect(flash.notice).to be_present
      end
    end

    context 'when the export is ready' do
      let(:export) { create(:export, groupe_instructeurs: [gi_1, gi_0], job_status: 'generated') }

      before do
        export.file.attach(io: StringIO.new('export'), filename: 'file.csv')
      end

      it 'displays the download link' do
        subject
        expect(response.headers['Location']).to start_with("http://test.host/rails/active_storage/disk")
      end
    end

    context 'when another export is ready' do
      let(:export) { create(:export, groupe_instructeurs: [gi_0]) }

      before do
        export.file.attach(io: StringIO.new('export'), filename: 'file.csv')
      end

      it 'displays an notice' do
        is_expected.to redirect_to(instructeur_procedure_url(procedure))
        expect(flash.notice).to be_present
      end
    end

    context 'when the turbo_stream format is used' do
      before do
        post :download_export,
          params: { export_format: :csv, procedure_id: procedure.id },
          format: :turbo_stream
      end

      it 'responds in the correct format' do
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when logged in through super admin' do
      let(:manager) { true }
      it { is_expected.to have_http_status(:forbidden) }
    end
  end

  describe '#create_multiple_commentaire' do
    let(:instructeur) { create(:instructeur) }
    let!(:gi_p1_1) { GroupeInstructeur.create(label: '1', procedure: procedure) }
    let!(:gi_p1_2) { GroupeInstructeur.create(label: '2', procedure: procedure) }
    let(:body) { "avant\napres" }
    let!(:dossier) { create(:dossier, state: "brouillon", procedure: procedure, groupe_instructeur: procedure.groupe_instructeurs.first) }
    let!(:dossier_2) { create(:dossier, state: "brouillon", procedure: procedure, groupe_instructeur: gi_p1_1) }
    let!(:dossier_3) { create(:dossier, state: "brouillon", procedure: procedure, groupe_instructeur: gi_p1_2) }
    let!(:procedure) { create(:procedure, :published, instructeurs: [instructeur]) }

    before do
      sign_in(instructeur.user)
      instructeur.groupe_instructeurs << gi_p1_1
      procedure
      post :create_multiple_commentaire,
      params: {
        procedure_id: procedure.id,
        commentaire: { body: body }
      }
    end

    it "creates a commentaire for 2 dossiers" do
      expect(Commentaire.all.count).to eq(2)
      expect(dossier.commentaires.first.body).to eq("avant\napres")
      expect(dossier_2.commentaires.first.body).to eq("avant\napres")
      expect(dossier_3.commentaires).to eq([])
    end

    it "creates a Bulk Message for 2 groupes instructeurs" do
      expect(BulkMessage.all.count).to eq(1)
      expect(BulkMessage.all.first.body).to eq("avant\napres")
      expect(BulkMessage.all.first.groupe_instructeurs.sort).to match([procedure.groupe_instructeurs.first, gi_p1_1])
    end

    it "creates a flash notice" do
      expect(flash.notice).to be_present
      expect(flash.notice).to eq("Tous les messages ont été envoyés avec succès")
    end

    it "redirect to instructeur_procedure_path" do
      expect(response).to redirect_to instructeur_procedure_path(procedure)
    end
  end
end
