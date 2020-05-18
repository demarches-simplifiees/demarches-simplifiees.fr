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
  end
end
