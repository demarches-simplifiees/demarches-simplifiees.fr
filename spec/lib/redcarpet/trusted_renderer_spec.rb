RSpec.describe Redcarpet::TrustedRenderer do
  let(:view_context) { ActionController::Base.new.view_context }
  subject(:renderer) { Redcarpet::Markdown.new(described_class.new(view_context), autolink: true) }

  context 'when rendering links' do
    it 'renders internal links without target and rel attributes' do
      markdown = "[Click here](/internal)"
      expect(renderer.render(markdown)).to include('<a href="/internal">Click here</a>')
    end

    it 'renders external links with target="_blank" and rel="noopener noreferrer"' do
      markdown = "[Visit](http://example.com)"
      expect(renderer.render(markdown)).to include('<a href="http://example.com" title="Nouvel onglet" target="_blank" rel="noopener noreferrer">Visit</a>')
    end
  end

  context 'when rendering images' do
    it 'renders an image tag with lazy loading' do
      markdown = "![A cute cat](http://example.com/cat.jpg)"
      expect(renderer.render(markdown)).to include('<img alt="A cute cat" loading="lazy" src="http://example.com/cat.jpg" />')
    end
  end

  context 'when autolinking' do
    it 'autolinks URLs' do
      markdown = "Visit http://example.com"
      expect(renderer.render(markdown)).to include('Visit <a href="http://example.com" title="Nouvel onglet" target="_blank" rel="noopener noreferrer">http://example.com</a>')
    end

    it 'autolinks email addresses with mailto' do
      markdown = "Email user@example.com"
      expect(renderer.render(markdown)).to include('<a href="mailto:user@example.com">user@example.com</a>')
    end
  end
end
