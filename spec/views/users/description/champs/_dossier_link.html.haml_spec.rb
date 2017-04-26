require 'spec_helper'

describe 'users/description/champs/dossier_link.html.haml', type: :view do
  let(:type_champ) { create(:type_de_champ_public, type_champ: :dossier_link) }

  before do
    render 'users/description/champs/dossier_link.html.haml', champ: champ
  end

  context 'in all cases' do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: nil) }

    it 'should render an input for the dossier link' do
      expect(rendered).to have_css("input[type=number][placeholder=#{champ.libelle}]")
    end
  end

  context 'When no dossier is provided' do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: nil) }

    it 'should not display the procedure libelle' do
      expect(rendered).to have_css('.text-info[style*="display: none"]')
    end

    it 'should not display a warning' do
      expect(rendered).to have_css('.text-warning[style*="display: none"]')
    end
  end

  context 'When a dossier whith a procedure is provided' do
    let!(:procedure) { create(:procedure) }
    let!(:dossier) { create(:dossier, procedure: procedure) }
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: dossier.id) }

    it 'should display the procedure libelle' do
      expect(rendered).not_to have_css('.text-info[style*="display: none"]')
    end

    it 'should not display a warning' do
      expect(rendered).to have_css('.text-warning[style*="display: none"]')
    end
  end

  context 'When a unknown dossier id is provided' do
    let!(:champ) { create(:champ, type_de_champ: type_champ, value: 666) }

    it 'should not display the procedure libelle' do
      expect(rendered).to have_css('.text-info[style*="display: none"]')
    end

    it 'should display a warning' do
      expect(rendered).not_to have_css('.text-warning[style*="display: none"]')
    end
  end
end
