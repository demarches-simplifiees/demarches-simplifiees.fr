# frozen_string_literal: true

describe WeasyprintService do
  let(:html) { '<html><body>Hello, World!</body></html>' }
  let(:options) { { procedure_id: 1, dossier_id: 2 } }

  describe '#generate_pdf' do
    context 'when the Weasyprint API responds successfully' do
      before do
        stub_request(:post, WEASYPRINT_URL)
          .with(body: { html: html, upstream_context: options })
          .to_return(body: 'PDF_DATA')
      end

      it 'returns a StringIO object with the PDF data' do
        pdf = described_class.generate_pdf(html, options)
        expect(pdf).to eq('PDF_DATA')
      end
    end
  end
end
