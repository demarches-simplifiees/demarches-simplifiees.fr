require 'spec_helper'

describe 'instructeurs/dossiers/state_button.html.haml', type: :view do
  include DossierHelper

  subject! do
    render('instructeurs/dossiers/state_button.html.haml', dossier: dossier)
  end

  matcher :have_dropdown_title do |expected_title|
    match do |rendered|
      expect(rendered).to have_selector('.dropdown .dropdown-button', text: expected_title)
    end
  end

  matcher :have_dropdown_items do |options|
    match do |rendered|
      expected_count = options[:count] || 1
      expect(rendered).to have_selector('ul.dropdown-items li', count: expected_count)
    end
  end

  matcher :have_dropdown_item do |expected_title, options = {}|
    match do |rendered|
      expected_href = options[:href]
      if (expected_href.present?)
        expect(rendered).to have_selector("ul.dropdown-items li a[href='#{expected_href}']", text: expected_title)
      else
        expect(rendered).to have_selector('ul.dropdown-items li', text: expected_title)
      end
    end
  end

  context 'brouillon' do
    # Currently the state button is not supposed to be displayed for brouillons.
    # But better have a sane fallback than crashing.
    let(:dossier) { create(:dossier) }

    it 'renders a dropdown' do
      expect(rendered).to have_dropdown_title('Brouillon')
      expect(rendered).to have_dropdown_items(count: 0)
    end
  end

  context 'en_contruction' do
    let(:dossier) { create(:dossier, :en_construction) }

    it 'renders a dropdown' do
      expect(rendered).to have_dropdown_title('En construction')
      expect(rendered).to have_dropdown_items(count: 2)
      expect(rendered).to have_dropdown_item('En construction')
      expect(rendered).to have_dropdown_item('Passer en instruction', href: passer_en_instruction_instructeur_dossier_path(dossier.procedure, dossier))
    end
  end

  context 'en_instruction' do
    let(:dossier) { create(:dossier, :en_instruction) }

    it 'renders a dropdown' do
      expect(rendered).to have_dropdown_title('En instruction')
      expect(rendered).to have_dropdown_items(count: 5)
      expect(rendered).to have_dropdown_item('Repasser en construction', href: repasser_en_construction_instructeur_dossier_path(dossier.procedure, dossier))
      expect(rendered).to have_dropdown_item('En instruction')
      expect(rendered).to have_dropdown_item('Accepter')
      expect(rendered).to have_dropdown_item('Classer sans suite')
      expect(rendered).to have_dropdown_item('Refuser')
    end
  end

  shared_examples 'a dropdown for a closed state' do |state|
    let(:dossier) { create :dossier, state }

    it 'renders a dropdown' do
      expect(rendered).to have_dropdown_title(dossier_display_state(dossier))
      expect(rendered).to have_dropdown_items(count: 1)
      expect(rendered).to have_dropdown_item('Repasser en instruction', href: repasser_en_instruction_instructeur_dossier_path(dossier.procedure, dossier))
    end

    context 'with a motivation' do
      let(:dossier) { create :dossier, state, :with_motivation }

      it 'displays the motivation text' do
        expect(rendered).to have_dropdown_item('Motivation')
        expect(rendered).to have_content(dossier.motivation)
      end
    end

    context 'with an attestation' do
      let(:dossier) { create :dossier, state, :with_attestation }

      it 'provides a link to the attestation' do
        expect(rendered).to have_dropdown_item('Voir l’attestation')
        expect(rendered).to have_link(href: attestation_instructeur_dossier_path(dossier.procedure, dossier))
      end
    end

    context 'with a justificatif' do
      let(:dossier) do
        dossier = create(:dossier, state, :with_justificatif)
        dossier.justificatif_motivation.blob.update(metadata: dossier.justificatif_motivation.blob.metadata.merge(virus_scan_result: ActiveStorage::VirusScanner::SAFE))
        dossier
      end

      it 'allows to download the justificatif' do
        expect(rendered).to have_dropdown_item('Justificatif')
        expect(rendered).to have_link(href: url_for(dossier.justificatif_motivation.attachment.blob))
      end
    end
  end

  context 'accepte' do
    it_behaves_like 'a dropdown for a closed state', :accepte
  end

  context 'refuse' do
    it_behaves_like 'a dropdown for a closed state', :refuse
  end

  context 'sans_suite' do
    it_behaves_like 'a dropdown for a closed state', :sans_suite
  end
end
