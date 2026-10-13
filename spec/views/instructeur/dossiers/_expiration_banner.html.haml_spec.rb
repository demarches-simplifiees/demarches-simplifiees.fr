# frozen_string_literal: true

describe 'instructeur/dossiers/expiration_banner', type: :view do
  include DossierHelper
  let(:duree_conservation_dossiers_dans_ds) { 3 }
  let(:dossier) do
    create(:dossier, state, attributes.merge(
                              state: state,
                              procedure: create(:procedure, duree_conservation_dossiers_dans_ds: duree_conservation_dossiers_dans_ds)
                            ))
  end
  let(:i18n_key_state) { state }
  subject do
    dossier.update_expired_at unless dossier.en_instruction?
    render('instructeurs/dossiers/expiration_banner',
           dossier: dossier,
           current_user: build(:user))
  end

  context 'with dossier.en_construction?' do
    let(:attributes) { { en_construction_at: 6.months.ago } }
    let(:state) { :en_construction }

    it 'does not render any expiration message (#13178)' do
      expect(subject).not_to have_selector('.expires_at')
      expect(subject).not_to have_selector('p.expires_at_en_instruction')
    end
  end

  context 'with dossier.en_processed_at?' do
    let(:state) { :accepte }
    let(:attributes) { {} }

    it 'render estimated expiration date' do
      allow(dossier).to receive(:processed_at).and_return(6.months.ago)
      expect(subject).to have_selector('.expires_at',
                                       text: I18n.t("shared.dossiers.header.expires_at.#{i18n_key_state}",
                                                    date: safe_expiration_date(dossier),
                                                    duree_conservation_totale: duree_conservation_dossiers_dans_ds))
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
end
