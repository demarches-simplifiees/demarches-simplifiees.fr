describe 'instructeurs/dossiers/instruction_button', type: :view do
  include DossierHelper

  subject! do
    render('instructeurs/dossiers/instruction_button', dossier: dossier)
  end

  matcher :have_dropdown_title do |expected_title|
    match do |rendered|
      expect(rendered).to have_selector('.dropdown .dropdown-button', text: expected_title)
    end
  end

  matcher :have_dropdown_items do |options|
    match do |rendered|
      expected_count = options[:count] || 1
      expect(rendered).to have_selector('ul.dropdown-items li:not(.hidden)', count: expected_count)
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

  context 'en_construction' do
    let(:dossier) { create(:dossier, :en_construction) }

    it 'renders a dropdown' do
      expect(rendered).to have_dropdown_title('Demander une correction')
      expect(rendered).to have_dropdown_items(count: 2) # form is already expanded so we have 2 visible items
    end
  end

  context 'en_instruction' do
    let(:dossier) { create(:dossier, :en_instruction) }

    it 'renders a dropdown' do
      expect(rendered).to have_dropdown_title('Instruire le dossier')
      expect(rendered).to have_dropdown_items(count: 4)
      expect(rendered).to have_dropdown_item('Accepter')
      expect(rendered).to have_dropdown_item('Classer sans suite')
      expect(rendered).to have_dropdown_item('Refuser')
      expect(rendered).to have_dropdown_item('Demander une correction')
    end
  end
end
