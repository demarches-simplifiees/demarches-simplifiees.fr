# frozen_string_literal: true

describe 'users/dossiers/dossiers_list', type: :view do
  let(:user) { dossier.user }

  subject do
    render 'users/dossiers/dossiers_list', dossiers: [dossier], current_user: user
  end
  before do
    [:paginate, :page_entries_info].map { allow(view).to receive(it).and_return("") }
  end
  context 'when procedure is not published and not path (sentry#6394294155)' do
    let(:discarded_procedure) { create(:procedure, :discarded) }
    let(:replaced_procedure) { create(:procedure, :closed, closing_reason: :internal_procedure, replaced_by_procedure: discarded_procedure) }
    let(:dossier) { create(:dossier, :en_construction, procedure: replaced_procedure) }

    it "renders successfully" do
      expect(subject).not_to have_link(commencer_path(replaced_procedure.path))
      expect(subject).not_to have_link(commencer_path(discarded_procedure.path))
    end
  end

  describe 'bandeau d\'information pour dossiers en construction supprimés' do
    let(:procedure) { create(:procedure) }

    before do
      assign(:statut, statut)
    end

    context 'quand on est sur l\'onglet dossiers-supprimes' do
      let(:statut) { 'dossiers-supprimes' }

      context 'avec un dossier en construction supprimé' do
        let(:dossier) { create(:dossier, :en_construction, :hidden_by_user, procedure: procedure) }

        it 'affiche le bandeau d\'information' do
          expect(subject).to have_selector('.fr-alert.fr-alert--info')
          expect(subject).to have_text("administration ne traitera plus votre demande")
        end

        it 'utilise les bonnes classes CSS pour le bandeau' do
          expect(subject).to have_selector('.fr-alert.fr-alert--info.fr-alert--sm.fr-mb-2w')
        end
      end

      context 'avec un dossier accepté supprimé' do
        let(:dossier) { create(:dossier, :accepte, :hidden_by_user, procedure: procedure) }

        it 'n\'affiche pas le bandeau d\'information' do
          expect(subject).not_to have_selector('.fr-alert.fr-alert--info')
          expect(subject).not_to have_text("administration ne traitera plus votre demande")
        end
      end

      context 'avec un dossier en instruction supprimé' do
        let(:dossier) { create(:dossier, :en_instruction, :hidden_by_user, procedure: procedure) }

        it 'n\'affiche pas le bandeau d\'information' do
          expect(subject).not_to have_selector('.fr-alert.fr-alert--info')
          expect(subject).not_to have_text("administration ne traitera plus votre demande")
        end
      end

      context 'avec un dossier refusé supprimé' do
        let(:dossier) { create(:dossier, :refuse, :hidden_by_user, procedure: procedure) }

        it 'n\'affiche pas le bandeau d\'information' do
          expect(subject).not_to have_selector('.fr-alert.fr-alert--info')
          expect(subject).not_to have_text("administration ne traitera plus votre demande")
        end
      end
    end

    context 'quand on n\'est pas sur l\'onglet dossiers-supprimes' do
      let(:statut) { 'en-cours' }

      context 'avec un dossier en construction' do
        let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

        it 'n\'affiche pas le bandeau d\'information' do
          expect(subject).not_to have_selector('.fr-alert.fr-alert--info')
          expect(subject).not_to have_text("administration ne traitera plus votre demande")
        end
      end
    end

    context 'avec plusieurs dossiers de différents états' do
      let(:statut) { 'dossiers-supprimes' }
      let(:dossier_en_construction) { create(:dossier, :en_construction, :hidden_by_user, procedure: procedure) }
      let(:dossier_accepte) { create(:dossier, :accepte, :hidden_by_user, procedure: procedure) }
      let(:dossiers) { [dossier_en_construction, dossier_accepte] }
      let(:user) { dossier_en_construction.user }

      subject do
        render 'users/dossiers/dossiers_list', dossiers: dossiers, current_user: user
      end

      it 'affiche le bandeau seulement pour le dossier en construction' do
        # Un seul bandeau pour le dossier en construction
        expect(subject).to have_selector('.fr-alert.fr-alert--info', count: 1)
        expect(subject).to have_text("administration ne traitera plus votre demande", count: 1)
      end
    end
  end
end
