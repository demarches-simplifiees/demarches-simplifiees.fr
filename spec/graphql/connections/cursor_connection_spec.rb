RSpec.describe Connections::CursorConnection do
  describe '.limit_and_inverted' do
    let(:max_page_size) { 100 }

    subject do
      cursor = Connections::CursorConnection.new(Dossier)
      allow(cursor).to receive(:max_page_size).and_return(max_page_size)
      limit, inverted = cursor.send(:limit_and_inverted, **args)
      { limit:,  inverted: }
    end

    context 'without explicit args' do
      let(:args) { { } }

      it { is_expected.to eq(limit: max_page_size + 1, inverted: false) }
    end

    context 'when asked for 2 first elements' do
      let(:args) { { first: 2 } }

      it { is_expected.to eq(limit: 3, inverted: false) }
    end

    context 'when asked for 2 first elements, in order desc' do
      let(:args) { { first: 2, order: :desc} }

      it { is_expected.to eq(limit: 3, inverted: true) }
    end

    context 'when exceeding the max_page_size' do
      let(:args) { { first: max_page_size + 1 } }

      it { is_expected.to eq(limit: max_page_size + 1, inverted: false) }
    end

    context 'when asked for 2 last elements' do
      let(:args) { { last: 2 } }

      it { is_expected.to eq(limit: 3, inverted: true) }
    end

    context 'when asked for 2 last elements, in order desc' do
      let(:args) { { last: 2, order: :desc} }

      it { is_expected.to eq(limit: 3, inverted: false) }
    end
 
    context '' do
      let(:args) { { after: :after, first: 2 } }

      it { is_expected.to eq(limit: 3, inverted: false) }
    end

    context '' do
      let(:args) { { before: :before, first: 2 } }

      it { is_expected.to eq(limit: 3, inverted: true) }
    end
  end
end
