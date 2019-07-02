describe 'shared/dossiers/messages/message.html.haml', type: :view do
  before { view.extend DossierHelper }

  subject { render 'shared/dossiers/messages/message.html.haml', commentaire: commentaire, messagerie_seen_at: seen_at, connected_user: dossier.user }

  let(:dossier) { create(:dossier, :en_construction) }
  let(:commentaire) { create(:commentaire, dossier: dossier) }
  let(:seen_at) { commentaire.created_at + 1.hour }

  context "with a seen_at after commentaire created_at" do
    let(:seen_at) { commentaire.created_at + 1.hour  }

    it { is_expected.not_to have_css(".highlighted") }
  end

  context "with a seen_at after commentaire created_at" do
    let(:seen_at) { commentaire.created_at - 1.hour  }

    it { is_expected.to have_css(".highlighted") }
  end
end
