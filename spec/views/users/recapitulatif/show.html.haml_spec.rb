require 'spec_helper'

describe 'users/recapitulatif/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_user, :with_entreprise, state: state, procedure: create(:procedure, :with_api_carto)) }
  let(:dossier_id) { dossier.id }
  let(:state) { 'draft' }

  before do
    assign(:facade, DossierFacades.new(dossier.id, dossier.user.email))
  end

  context 'sur la rendered recapitulative' do
    context 'test de composition de la page' do
      before do
        render
      end

      it 'la section infos dossier est présente' do
        expect(rendered).to have_selector('#infos_dossier')
      end

      it 'le flux de commentaire est présent' do
        expect(rendered).to have_selector('#commentaires_flux')
      end

      it 'le numéro de dossier est présent' do
        expect(rendered).to have_selector('#dossier_id')
        expect(rendered).to have_content(dossier_id)
      end

      context 'les liens de modifications' do
        context 'lien description' do
          it 'le lien vers description est présent' do
            expect(rendered).to have_css('#maj_infos')
          end

          it 'le lien vers description est correct' do
            expect(rendered).to have_selector("a[id=maj_infos][href='/users/dossiers/#{dossier_id}/description']")
          end
        end

        context 'lien carte' do
          it 'le lien vers carte est présent' do
            expect(rendered).to have_css('#maj_carte')
          end

          it 'le lien vers description est correct' do
            expect(rendered).to have_selector("a[id=maj_carte][href='/users/dossiers/#{dossier_id}/carte']")
          end
        end
      end
    end

    context 'buttons to change dossier state' do
      context 'when dossier state is initiated' do
        let(:state) { 'initiated' }
        before do
          render
        end

        it { expect(rendered).to have_content('Soumis') }
      end

      context 'when dossier state is replied' do
        let(:state) { 'replied' }

        before do
          render
        end

        it { expect(rendered).to have_content('Répondu') }
      end

      context 'when dossier state is updated' do
        let(:state) { 'updated' }

        before do
          render
        end

        it { expect(rendered).to have_content('Mis à jour') }
      end

      context 'when dossier state is validated' do
        let(:state) { 'validated' }

        before do
          render
        end

        it 'button Déposer mon dossier est present' do
          expect(rendered).to have_css('#validate_button')
          expect(rendered).to have_content('Déposer mon dossier')
        end

        it 'button Editer mon dossier n\'est plus present' do
          expect(rendered).not_to have_css('#maj_infos')
          expect(rendered).not_to have_content('Editer mon dossier')
        end
      end

      context 'when dossier state is submitted' do
        let(:state) { 'submitted' }

        before do
          render
        end

        it { expect(rendered).to have_content('Déposé') }

        it 'button Editer mon dossier n\'est plus present' do
          expect(rendered).not_to have_css('#maj_infos')
          expect(rendered).not_to have_content('Editer mon dossier')
        end
      end

      context 'when dossier state is traité' do
        let(:state) { 'closed' }

        before do
          render
        end
        it { expect(rendered).to have_content('Traité') }

        it 'button Editer mon dossier n\'est plus present' do
          expect(rendered).not_to have_css('#maj_infos')
          expect(rendered).not_to have_content('Editer mon dossier')
        end
      end
    end
  end
end
