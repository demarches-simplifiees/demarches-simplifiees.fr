# frozen_string_literal: true

describe 'instructeur/dossiers/expiration_banner', type: :view do
  include DossierHelper

  subject do
    dossier.update_expired_at
    render('instructeurs/dossiers/expiration_banner',
           dossier: dossier,
           current_user: build(:user))
  end

  context 'with dossier.en_construction?' do
    let(:dossier) { dossiers.en_construction }

    it 'does not render any expiration message (#13178)' do
      expect(subject).not_to have_selector('.expires_at')
      expect(subject).not_to have_selector('p.expires_at_en_instruction')
    end
  end

  context 'with dossier.en_processed_at?' do
    let(:dossier) { dossiers.accepte }

    it 'render estimated expiration date' do
      expect(subject).to have_selector('.expires_at',
                                       text: I18n.t("shared.dossiers.header.expires_at.accepte",
                                                    date: safe_expiration_date(dossier),
                                                    duree_conservation_totale: dossier.procedure.duree_conservation_dossiers_dans_ds))
    end
  end

  context 'with a termine dossier close to expiration' do
    let(:dossier) { dossiers.accepte }

    before { dossier.update_column(:termine_close_to_expiration_notice_sent_at, 1.week.ago) }

    it 'renders the postpone button' do
      expect(subject).to have_selector('.fr-callout', text: I18n.t('instructeurs.dossiers.header.banner.title'))
      expect(subject).to have_button(id: 'test-instructeur-repousser-expiration')
    end
  end

  context 'with a termine dossier that has expired' do
    let(:dossier) { dossiers.accepte }

    before { dossier.update_column(:termine_close_to_expiration_notice_sent_at, 3.weeks.ago) }

    it 'does not render the postpone button' do
      expect(subject).to have_selector('.fr-callout', text: I18n.t('instructeurs.dossiers.header.banner.title_expired'))
      expect(subject).not_to have_button(id: 'test-instructeur-repousser-expiration')
    end
  end
end
