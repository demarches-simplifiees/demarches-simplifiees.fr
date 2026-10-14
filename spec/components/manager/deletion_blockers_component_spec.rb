# frozen_string_literal: true

RSpec.describe Manager::DeletionBlockersComponent, type: :component do
  include Rails.application.routes.url_helpers

  subject { render_inline(described_class.new(user:)) }

  context 'when nothing blocks the deletion' do
    let(:user) { create(:user) }

    it { expect(subject.to_html).to be_blank }
  end

  context 'when the user holds roles' do
    let(:user) { administrateurs.default.user }

    it 'links to the role pages' do
      expect(subject).to have_link('administrateur', href: manager_administrateur_path(administrateurs.default))
      expect(subject).to have_link('instructeur', href: manager_instructeur_path(user.instructeur))
    end
  end

  context 'when the expert answered avis' do
    let(:user) { experts.default.user }

    it 'lists the dossiers to contact about' do
      expect(subject).to have_text('il a répondu à 2 avis')
      expect(subject).to have_link("dossier nº #{dossiers.accepte.id}", href: manager_dossier_path(dossiers.accepte))
      expect(subject).to have_link(procedures.individual.libelle, href: manager_procedure_path(procedures.individual))
      expect(subject).to have_text("demandé par #{instructeurs.default.email}")
      expect(subject).to have_text('historique des dossiers')
    end
  end

  context 'when the expert requested an avis and wrote messages' do
    let(:expert) { create(:expert) }
    let(:user) { expert.user }
    let!(:avis) { create(:avis, claimant: expert, dossier: dossiers.en_instruction) }

    before { create(:commentaire, expert:, email: expert.email, dossier: dossiers.en_instruction) }

    it 'names the asked expert and counts the messages' do
      expect(subject).to have_text("demandé à #{avis.expert.email}")
      expect(subject).to have_text('il a écrit un message')
    end
  end
end
