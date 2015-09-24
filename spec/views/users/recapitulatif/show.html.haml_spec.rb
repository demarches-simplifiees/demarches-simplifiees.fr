require 'spec_helper'

describe 'users/recapitulatif/show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, :with_procedure, :with_user) }
  let(:dossier_id) { dossier.id }

  before do
    assign(:dossier, dossier.decorate)
    assign(:procedure, dossier.procedure)
    assign(:commentaires, dossier.commentaires)
    render
  end

  context 'sur la rendered recapitulative' do
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
          expect(rendered).to have_selector("a[id=maj_infos][href='/users/dossiers/#{dossier_id}/description?back_url=recapitulatif']")
        end
      end
    end

    # context 'visibilité Félicitation' do
    #   it 'Est affiché quand l\'on vient de la rendered description hors modification' do
    #     expect(rendered).to have_content('Félicitation')
    #   end
    #
    #   it 'N\'est pas affiché quand l\'on vient d\'une autre la rendered que description' do
    #     Capybara.current_session.driver.header('Referer', '/')
    #
    #     expect(rendered).to_not have_content('Félicitation')
    #   end
    #
    #   it 'N\'est pas affiché quand l\'on vient de la rendered description en modification' do
    #     Capybara.current_session.driver.header('Referer', '/description?back_url=recapitulatif')
    #
    #     expect(rendered).to_not have_content('Félicitation')
    #   end
    # end
  end



end
