require 'spec_helper'

describe NewGestionnaire::ProceduresController, type: :controller do
  describe "before_action: ensure_ownership!" do
    it "is present" do
      before_actions = NewGestionnaire::ProceduresController
        ._process_action_callbacks
        .find_all{|process_action_callbacks| process_action_callbacks.kind == :before}
        .map(&:filter)

      expect(before_actions).to include(:ensure_ownership!)
    end
  end

  describe "ensure_ownership!" do
    let(:gestionnaire) { create(:gestionnaire) }

    before do
      @controller.params[:procedure_id] = asked_procedure.id
      expect(@controller).to receive(:current_gestionnaire).and_return(gestionnaire)
      allow(@controller).to receive(:redirect_to)

      @controller.send(:ensure_ownership!)
    end

    context "when a gestionnaire asks for its procedure" do
      let(:asked_procedure) { create(:procedure, gestionnaires: [gestionnaire]) }

      it "does not redirects nor flash" do
        expect(@controller).not_to have_received(:redirect_to)
        expect(flash.alert).to eq(nil)
      end
    end

    context "when a gestionnaire asks for another procedure" do
      let(:asked_procedure) { create(:procedure) }

      it "redirects and flash" do
        expect(@controller).to have_received(:redirect_to).with(root_path)
        expect(flash.alert).to eq("Vous n'avez pas accès à cette procédure")
      end
    end
  end

  describe "before_action: redirect_to_avis_if_needed" do
    it "is present" do
      before_actions = NewGestionnaire::ProceduresController
        ._process_action_callbacks
        .find_all{|process_action_callbacks| process_action_callbacks.kind == :before}
        .map(&:filter)

      expect(before_actions).to include(:redirect_to_avis_if_needed)
    end
  end

  describe "redirect_to_avis_if_needed" do
    let(:gestionnaire) { create(:gestionnaire) }

    before do
      expect(@controller).to receive(:current_gestionnaire).at_least(:once).and_return(gestionnaire)
      allow(@controller).to receive(:redirect_to)
    end

    context "when a gestionnaire has some procedures" do
      let!(:some_procedure) { create(:procedure, gestionnaires: [gestionnaire]) }

      before { @controller.send(:redirect_to_avis_if_needed) }

      it "does not redirects nor flash" do
        expect(@controller).not_to have_received(:redirect_to)
      end
    end

    context "when a gestionnaire has no procedure and some avis" do
      before do
        Avis.create!(dossier: create(:dossier), claimant: create(:gestionnaire), gestionnaire: gestionnaire)
        @controller.send(:redirect_to_avis_if_needed)
      end

      it "redirects avis" do
        expect(@controller).to have_received(:redirect_to).with(avis_index_path)
      end
    end
  end

  describe "#index" do
    let(:gestionnaire) { create(:gestionnaire) }
    subject { get :index }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path)}
    end

    context "when logged in" do
      before { sign_in(gestionnaire) }

      it { expect(response).to have_http_status(:ok) }

      context "with procedures assigned" do
        let(:procedure1) { create(:procedure, :published) }
        let(:procedure2) { create(:procedure, :published, :archived) }
        let(:procedure3) { create(:procedure) }

        before do
          gestionnaire.procedures << procedure1
          gestionnaire.procedures << procedure2
          gestionnaire.procedures << procedure3
          subject
        end

        it { expect(assigns(:procedures)).to include(procedure1, procedure2) }
      end

      context "with dossiers" do
        let(:procedure) { create(:procedure, :published) }
        let(:dossier) { create(:dossier, state: state, procedure: procedure) }

        before do
          gestionnaire.procedures << procedure
          dossier
        end

        context "with brouillon state" do
          let(:state) { "brouillon" }
          before { subject }

          it { expect(assigns(:dossiers_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure.id]).to eq(nil) }
        end

        context "with not draft state on multiple procedures" do
          let(:procedure2) { create(:procedure, :published) }
          let(:state) { "en_construction" }

          before do
            create(:dossier, procedure: procedure, state: "en_construction")
            create(:dossier, procedure: procedure, state: "received")
            create(:dossier, procedure: procedure, state: "without_continuation", archived: true)

            gestionnaire.procedures << procedure2
            create(:dossier, :followed, procedure: procedure2, state: "en_construction")
            create(:dossier, procedure: procedure2, state: "closed")
            gestionnaire.followed_dossiers << create(:dossier, procedure: procedure2, state: "received")

            subject
          end

          it { expect(assigns(:dossiers_count_per_procedure)[procedure.id]).to eq(3) }
          it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure.id]).to eq(3) }
          it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure.id]).to eq(nil) }
          it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure.id]).to eq(1) }
          it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure.id]).to eq(nil) }

          it { expect(assigns(:dossiers_count_per_procedure)[procedure2.id]).to eq(3) }
          it { expect(assigns(:dossiers_a_suivre_count_per_procedure)[procedure2.id]).to eq(nil) }
          it { expect(assigns(:followed_dossiers_count_per_procedure)[procedure2.id]).to eq(1) }
          it { expect(assigns(:dossiers_archived_count_per_procedure)[procedure2.id]).to eq(nil) }
          it { expect(assigns(:dossiers_termines_count_per_procedure)[procedure2.id]).to eq(1) }
        end
      end
    end
  end

  describe "#show" do
    let(:gestionnaire) { create(:gestionnaire) }
    let!(:procedure) { create(:procedure, gestionnaires: [gestionnaire]) }

    context "when logged in" do
      before do
        sign_in(gestionnaire)
      end

      context "without anything" do
        before { get :show, params: { procedure_id: procedure.id } }

        it { expect(response).to have_http_status(:ok) }
        it { expect(assigns(:procedure)).to eq(procedure) }
      end

      context 'with a new brouillon dossier' do
        let!(:brouillon_dossier) { create(:dossier, procedure: procedure, state: 'draft') }

        before do
          get :show, params: { procedure_id: procedure.id }
        end

        it { expect(assigns(:a_suivre_dossiers)).to be_empty }
        it { expect(assigns(:followed_dossiers)).to be_empty }
        it { expect(assigns(:termines_dossiers)).to be_empty }
        it { expect(assigns(:all_state_dossiers)).to be_empty }
        it { expect(assigns(:archived_dossiers)).to be_empty }
      end

      context 'with a new dossier without follower' do
        let!(:new_unfollow_dossier) { create(:dossier, procedure: procedure, state: 'received') }

        before do
          get :show, params: { procedure_id: procedure.id }
        end

        it { expect(assigns(:a_suivre_dossiers)).to match([new_unfollow_dossier]) }
        it { expect(assigns(:followed_dossiers)).to be_empty }
        it { expect(assigns(:termines_dossiers)).to be_empty }
        it { expect(assigns(:all_state_dossiers)).to match([new_unfollow_dossier]) }
        it { expect(assigns(:archived_dossiers)).to be_empty }
      end

      context 'with a new dossier with a follower' do
        let!(:new_followed_dossier) { create(:dossier, procedure: procedure, state: 'received') }

        before do
          gestionnaire.followed_dossiers << new_followed_dossier
          get :show, params: { procedure_id: procedure.id }
        end

        it { expect(assigns(:a_suivre_dossiers)).to be_empty }
        it { expect(assigns(:followed_dossiers)).to match([new_followed_dossier]) }
        it { expect(assigns(:termines_dossiers)).to be_empty }
        it { expect(assigns(:all_state_dossiers)).to match([new_followed_dossier]) }
        it { expect(assigns(:archived_dossiers)).to be_empty }
      end

      context 'with a termine dossier with a follower' do
        let!(:termine_dossier) { create(:dossier, procedure: procedure, state: 'closed') }

        before do
          get :show, params: { procedure_id: procedure.id }
        end

        it { expect(assigns(:a_suivre_dossiers)).to be_empty }
        it { expect(assigns(:followed_dossiers)).to be_empty }
        it { expect(assigns(:termines_dossiers)).to match([termine_dossier]) }
        it { expect(assigns(:all_state_dossiers)).to match([termine_dossier]) }
        it { expect(assigns(:archived_dossiers)).to be_empty }
      end

      context 'with an archived dossier' do
        let!(:archived_dossier) { create(:dossier, procedure: procedure, state: 'received', archived: true) }

        before do
          get :show, params: { procedure_id: procedure.id }
        end

        it { expect(assigns(:a_suivre_dossiers)).to be_empty }
        it { expect(assigns(:followed_dossiers)).to be_empty }
        it { expect(assigns(:termines_dossiers)).to be_empty }
        it { expect(assigns(:all_state_dossiers)).to be_empty }
        it { expect(assigns(:archived_dossiers)).to match([archived_dossier]) }
      end

      describe 'statut' do
        let!(:a_suivre__dossier) { Timecop.freeze(1.day.ago){ create(:dossier, procedure: procedure, state: 'received') } }
        let!(:new_followed_dossier) { Timecop.freeze(2.day.ago){ create(:dossier, procedure: procedure, state: 'received') } }
        let!(:termine_dossier) { Timecop.freeze(3.day.ago){ create(:dossier, procedure: procedure, state: 'closed') } }
        let!(:archived_dossier) { Timecop.freeze(4.day.ago){ create(:dossier, procedure: procedure, state: 'received', archived: true) } }

        before do
          gestionnaire.followed_dossiers << new_followed_dossier
          get :show, params: { procedure_id: procedure.id, statut: statut }
        end

        context 'when statut is empty' do
          let(:statut) { nil }

          it { expect(assigns(:dossiers)).to match([a_suivre__dossier]) }
          it { expect(assigns(:statut)).to eq('a-suivre') }
        end

        context 'when statut is a-suivre' do
          let(:statut) { 'a-suivre' }

          it { expect(assigns(:statut)).to eq('a-suivre') }
          it { expect(assigns(:dossiers)).to match([a_suivre__dossier]) }
        end

        context 'when statut is suivis' do
          let(:statut) { 'suivis' }

          it { expect(assigns(:statut)).to eq('suivis') }
          it { expect(assigns(:dossiers)).to match([new_followed_dossier]) }
        end

        context 'when statut is traites' do
          let(:statut) { 'traites' }

          it { expect(assigns(:statut)).to eq('traites') }
          it { expect(assigns(:dossiers)).to match([termine_dossier]) }
        end

        context 'when statut is tous' do
          let(:statut) { 'tous' }

          it { expect(assigns(:statut)).to eq('tous') }
          it { expect(assigns(:dossiers)).to match_array([a_suivre__dossier, new_followed_dossier, termine_dossier]) }
        end

        context 'when statut is archives' do
          let(:statut) { 'archives' }

          it { expect(assigns(:statut)).to eq('archives') }
          it { expect(assigns(:dossiers)).to match([archived_dossier]) }
        end
      end
    end
  end
end
