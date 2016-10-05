require 'spec_helper'

describe 'users/recapitulatif/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, state: state, procedure: create(:procedure, :with_api_carto, :with_two_type_de_piece_justificative, for_individual: true, individual_with_siret: true)) }
  let(:dossier_id) { dossier.id }
  let(:state) { 'draft' }

  before do
    sign_in dossier.user
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

      describe 'les liens de modifications' do
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
            expect(rendered).to have_css('#maj_pj')
          end
        end

        context 'lien carte' do
          it 'le lien vers le renseignement un SIRET est présent' do
            expect(rendered).to have_css('#add_siret')
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

        it { expect(rendered).to have_content('Nouveau') }

        it 'button Modifier les document est present' do
          expect(rendered).to have_content('Modifier les documents')
          expect(rendered).to have_css('#UploadPJmodal')
        end

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
          expect(rendered).not_to have_content('Modifier mon dossier')
        end

        it 'button Modifier les document n\'est plus present' do
          expect(rendered).not_to have_content('Modifier les documents')
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
          expect(rendered).not_to have_content('Modifier mon dossier')
        end
      end

      context 'when dossier state is closed' do
        let(:state) { 'closed' }

        before do
          render
        end
        it { expect(rendered).to have_content('Accepté') }

        it 'button Editer mon dossier n\'est plus present' do
          expect(rendered).not_to have_css('#maj_infos')
          expect(rendered).not_to have_content('Modifier mon dossier')
        end
      end

      context 'when dossier state is refused' do
        let(:state) { 'refused' }

        before do
          render
        end
        it { expect(rendered).to have_content('Refusé') }

        it 'button Editer mon dossier n\'est plus present' do
          expect(rendered).not_to have_css('#maj_infos')
          expect(rendered).not_to have_content('Modifier mon dossier')
        end
      end

      context 'when dossier state is without_continuation' do
        let(:state) { 'without_continuation' }

        before do
          render
        end
        it { expect(rendered).to have_content('Sans suite') }

        it 'button Editer mon dossier n\'est plus present' do
          expect(rendered).not_to have_css('#maj_infos')
          expect(rendered).not_to have_content('Modifier mon dossier')
        end
      end
    end

    context 'when invite is logged' do

      context 'when invite is by Gestionnaire' do
        let!(:invite_user) { create(:user, email: 'invite@octo.com') }

        before do
          create(:invite) { create(:invite, email: invite_user.email, user: invite_user, dossier: dossier) }
          sign_out dossier.user
          sign_in invite_user
          render
        end

        describe 'les liens de modifications' do
          it 'describe link is not present' do
            expect(rendered).not_to have_css('#maj_infos')
          end

          it 'map link is not present' do
            expect(rendered).not_to have_css('#maj_carte')
          end

          it 'PJ link is not present' do
            expect(rendered).not_to have_css('#maj_pj')
          end

          it 'archive link is not present' do
            expect(rendered).not_to have_content('Archiver')
          end
        end

        context 'when dossier is validated' do
          let(:state) { 'validated' }

          before do
            render
          end

          it 'submitted link is not present' do
            expect(rendered).not_to have_content('Déposer mon dossier')
          end
        end
      end

      context 'invite is by User' do
        let!(:invite_user) { create(:user, email: 'invite@octo.com') }

        before do
          create(:invite) { create(:invite, email: invite_user.email, user: invite_user, dossier: dossier, type: 'InviteUser') }
          sign_out dossier.user
          sign_in invite_user
          render
        end

        describe 'les liens de modifications' do
          it 'describe link is not present' do
            expect(rendered).to have_css('#maj_infos')
          end

          it 'map link is present' do
            expect(rendered).to have_css('#maj_carte')
          end

          it 'PJ link is present' do
            expect(rendered).to have_css('#maj_pj')
          end

          it 'archive link is present' do
            expect(rendered).not_to have_content('Archiver')
          end
        end

        context 'when dossier is validated' do
          let(:state) { 'validated' }

          before do
            render
          end

          it 'submitted link is not present' do
            expect(rendered).not_to have_content('Déposer mon dossier')
          end
        end
      end
    end
  end
end
