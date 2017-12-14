describe 'new_gestionnaire/shared/commentaires/commentaire.html.haml', type: :view do
  before { view.extend DossierHelper }

  subject { render 'new_gestionnaire/shared/commentaires/commentaire.html.haml', commentaire: commentaire, messagerie_seen_at: seen_at, current_gestionnaire: current_gestionnaire }

  let(:dossier) { create(:dossier) }
  let(:commentaire) { create(:commentaire, dossier: dossier) }
  let(:current_gestionnaire) { create(:gestionnaire) }
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
