# frozen_string_literal: true

describe OCRService do
  include Dry::Monads[:result]

  describe '#analyze' do
    context 'when the service is enabled' do
      let(:ocr_service_url) { 'http://an_ocr_service/analyze' }
      let(:blob_url) { 'http://example.com/blob.pdf' }
      let(:blob) { double('Blob', url: blob_url) }

      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("OCR_SERVICE_URL", nil)
          .and_return(ocr_service_url)
      end

      context 'when the OCR service responds successfully' do
        let(:body) do
          {
            "2ddoc": nil,
            "rib": {
              "account_holder": ["Mme Titulaire", "58 BD ROBERT", "13284 MARSEILLE CEDEX 07"],
              "iban": "FR76 6666 6666 6666 6666 6666 780",
              "bic": "BICUFRP1"
            }
          }
        end

        before do
          stub_request(:post, ocr_service_url)
            .with(body: { url: blob_url, hint: { type: 'rib' } })
            .to_return(body: body.to_json, status: 200)
        end

        it 'returns a StringIO object with the PDF data' do
          analysis = described_class.analyze(blob)
          expect(analysis).to eq(Success(body))
        end
      end

      context 'when the OCR service responds with an error' do
        before do
          stub_request(:post, ocr_service_url)
            .with(body: { url: blob_url, hint: { type: 'rib' } })
            .to_return(status: 422, body: { error: 'Invalid request' }.to_json)
        end

        it 'handles the error gracefully' do
          analysis = described_class.analyze(blob)
          expect(analysis.failure?).to be true
          expect(analysis.failure[:code]).to eq(422)
          expect(analysis.failure[:reason].to_s).to include('Invalid')
        end
      end
    end
  end
end
