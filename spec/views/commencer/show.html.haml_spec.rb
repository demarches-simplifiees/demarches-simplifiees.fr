RSpec.describe 'commencer/show.html.haml', type: :view do
  include Rails.application.routes.url_helpers

  let(:procedure) { create(:procedure, :published, :for_individual, :with_service) }

  before do
    assign(:procedure, procedure)
    assign(:revision, procedure.published_revision)
    if user
      sign_in user
    end
  end

  subject { render }

  context 'when no user is signed in' do
    let(:user) { nil }

    it 'renders sign-in and sign-up links' do
      subject
      expect(rendered).to have_link('Créer un compte')
      expect(rendered).to have_link('J’ai déjà un compte')
      expect(rendered).to have_link('S’identifier avec FranceConnect')
    end
  end

  context 'when the user is already signed in' do
    let(:user) { create :user }

    shared_examples_for 'it renders a link to create a new dossier' do |button_label|
      it 'renders a link to create a new dossier' do
        subject
        expect(rendered).to have_link(button_label, href: new_dossier_url(procedure_id: procedure.id))
      end
    end

    context 'and they don’t have any dossier on this procedure' do
      it_behaves_like 'it renders a link to create a new dossier', 'Commencer la démarche'
    end

    context 'and they have a pending draft' do
      let!(:brouillon) { create(:dossier, user: user, procedure: procedure) }

      it_behaves_like 'it renders a link to create a new dossier', 'Commencer un nouveau dossier'

      it 'renders a link to resume the pending draft' do
        subject
        expect(rendered).to have_text(time_ago_in_words(brouillon.created_at))
        expect(rendered).to have_link('Continuer à remplir mon dossier', href: brouillon_dossier_path(brouillon))
      end
    end

    context 'and they have a submitted dossier' do
      let!(:brouillon) { create(:dossier, user: user, procedure: procedure) }
      let!(:dossier) { create(:dossier, :en_construction, :with_individual, user: user, procedure: procedure) }

      it_behaves_like 'it renders a link to create a new dossier', 'Commencer un nouveau dossier'

      it 'renders a link to the submitted dossier' do
        subject
        expect(rendered).to have_text(time_ago_in_words(dossier.depose_at))
        expect(rendered).to have_link('Voir mon dossier', href: dossier_path(dossier))
      end
    end

    context 'and they have several submitted dossiers' do
      let!(:brouillon) { create(:dossier, user: user, procedure: procedure) }
      let!(:dossiers) { create_list(:dossier, 2, :en_construction, :with_individual, user: user, procedure: procedure) }

      it_behaves_like 'it renders a link to create a new dossier', 'Commencer un nouveau dossier'

      it 'renders a link to the dossiers list' do
        subject
        expect(rendered).to have_link('Voir mes dossiers en cours', href: dossiers_path)
      end
    end

    context 'and they have a prefilled dossier' do
      let!(:prefilled_dossier) { create(:dossier, :prefilled, user: user, procedure: procedure) }

      before { assign(:prefilled_dossier, prefilled_dossier) }

      it_behaves_like 'it renders a link to create a new dossier', 'Commencer un nouveau dossier'

      it 'renders a link to resume the pending draft' do
        subject
        expect(rendered).to have_text(time_ago_in_words(prefilled_dossier.created_at))
        expect(rendered).to have_link('Continuer à remplir mon dossier', href: brouillon_dossier_path(prefilled_dossier))
      end
    end
  end
end
