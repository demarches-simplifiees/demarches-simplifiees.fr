describe 'shared/dossiers/messages/message.html.haml', type: :view do
  before { view.extend DossierHelper }

  subject { render 'shared/dossiers/messages/message.html.haml', commentaire: commentaire, messagerie_seen_at: seen_at, connected_user: dossier.user, show_reply_button: true }

  let(:dossier) { create(:dossier, :en_construction) }
  let(:commentaire) { create(:commentaire, dossier: dossier) }
  let(:seen_at) { commentaire.created_at + 1.hour }

  it { is_expected.to have_button("Répondre") }

  context "with a seen_at after commentaire created_at" do
    let(:seen_at) { commentaire.created_at + 1.hour  }

    it { is_expected.not_to have_css(".highlighted") }
  end

  context "with a seen_at after commentaire created_at" do
    let(:seen_at) { commentaire.created_at - 1.hour  }

    it { is_expected.to have_css(".highlighted") }
  end

  context 'with an instructeur message' do
    let(:instructeur) { create(:instructeur) }
    let(:procedure) { create(:procedure) }
    let(:commentaire) { create(:commentaire, instructeur: instructeur, body: 'Second message') }
    let(:dossier) { create(:dossier, :en_construction, commentaires: [commentaire], procedure: procedure) }

    context 'on a procedure with anonymous instructeurs' do
      before { Flipper.enable_actor(:hide_instructeur_email, procedure) }

      context 'redacts the instructeur email' do
        it { is_expected.to have_text(commentaire.body) }
        it { is_expected.to have_text("Instructeur n° #{instructeur.id}") }
        it { is_expected.not_to have_text(instructeur.email) }
      end
    end

    context 'on a procedure where instructeurs names are not redacted' do
      before { Flipper.disable_actor(:hide_instructeur_email, procedure) }

      context 'redacts the instructeur email but keeps the name' do
        it { is_expected.to have_text(commentaire.body) }
        it { is_expected.to have_text(instructeur.email.split('@').first) }
        it { is_expected.not_to have_text(instructeur.email) }
      end
    end

    describe 'delete message button for instructeur' do
      let(:instructeur) { create(:instructeur) }
      let(:procedure) { create(:procedure) }
      let(:dossier) { create(:dossier, :en_construction, commentaires: [commentaire], procedure: procedure) }
      subject { render 'shared/dossiers/messages/message.html.haml', commentaire: commentaire, messagerie_seen_at: seen_at, connected_user: instructeur, show_reply_button: true }
      let(:form_url) { instructeur_commentaire_path(commentaire.dossier.procedure, commentaire.dossier, commentaire) }

      context 'on a procedure where commentaire had been written by connected instructeur' do
        let(:commentaire) { create(:commentaire, instructeur: instructeur, body: 'Second message') }

        it { is_expected.to have_selector("form[action=\"#{form_url}\"]") }
      end

      context 'on a procedure where commentaire had been written by connected instructeur and discarded' do
        let(:commentaire) { create(:commentaire, instructeur: instructeur, body: 'Second message', discarded_at: 2.days.ago) }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
        it { is_expected.not_to have_selector(".rich-text", text: I18n.t(t('views.shared.commentaires.destroy.deleted_body'))) }
      end

      context 'on a procedure where commentaire had been written by connected an user' do
        let(:commentaire) { create(:commentaire, email: create(:user).email, body: 'Second message') }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
      end

      context 'on a procedure where commentaire had been written by connected an expert' do
        let(:commentaire) { create(:commentaire, expert: create(:expert), body: 'Second message') }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
      end

      context 'on a procedure where commentaire had been written another instructeur' do
        let(:commentaire) { create(:commentaire, instructeur: create(:instructeur), body: 'Second message') }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
      end
    end
  end

  context 'with an expert message' do
    describe 'delete message button for expert' do
      let(:expert) { create(:expert) }
      let(:procedure) { create(:procedure) }
      let(:dossier) { create(:dossier, :en_construction, commentaires: [commentaire], procedure: procedure) }
      let(:experts_procedure) { create(:experts_procedure, procedure: procedure, expert: expert) }
      let!(:avis) { create(:avis, email: nil, experts_procedure: experts_procedure) }
      subject { render 'shared/dossiers/messages/message.html.haml', commentaire: commentaire, messagerie_seen_at: seen_at, connected_user: expert, show_reply_button: true }
      let(:form_url) { delete_commentaire_expert_avis_path(avis.procedure, avis, commentaire: commentaire) }

      before do
        assign(:avis, avis)
      end

      context 'on a procedure where commentaire had been written by connected expert' do
        let(:commentaire) { create(:commentaire, expert: expert, body: 'Second message') }

        it { is_expected.to have_selector("form[action=\"#{form_url}\"]") }
      end

      context 'on a procedure where commentaire had been written by connected expert and discarded' do
        let(:commentaire) { create(:commentaire, expert: expert, body: 'Second message', discarded_at: 2.days.ago) }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
        it { is_expected.not_to have_selector(".rich-text", text: I18n.t(t('views.shared.commentaires.destroy.deleted_body'))) }
      end

      context 'on a procedure where commentaire had been written by connected an user' do
        let(:commentaire) { create(:commentaire, email: create(:user).email, body: 'Second message') }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
      end

      context 'on a procedure where commentaire had been written by connected an instructeur' do
        let(:commentaire) { create(:commentaire, instructeur: create(:instructeur), body: 'Second message') }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
      end

      context 'on a procedure where commentaire had been written another expert' do
        let(:commentaire) { create(:commentaire, expert: create(:expert), body: 'Second message') }

        it { is_expected.not_to have_selector("form[action=\"#{form_url}\"]") }
      end
    end
  end
end
