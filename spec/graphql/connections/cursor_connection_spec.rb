# frozen_string_literal: true

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
      let(:args) { {} }

      it { is_expected.to eq(limit: max_page_size + 1, inverted: false) }
    end

    context 'when asked for 2 first elements' do
      let(:args) { { first: 2 } }

      it { is_expected.to eq(limit: 3, inverted: false) }
    end

    context 'when exceeding the max_page_size' do
      let(:args) { { first: max_page_size + 1 } }

      it { is_expected.to eq(limit: max_page_size + 1, inverted: false) }
    end

    context 'when asked for 2 last elements' do
      let(:args) { { last: 2 } }

      it { is_expected.to eq(limit: 3, inverted: true) }
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

  describe '.previous_page?' do
    let(:after) { nil }
    let(:result_size) { nil }
    let(:limit) { nil }
    let(:inverted) { false }

    subject do
      cursor = Connections::CursorConnection.new(Dossier)
      cursor.send(:previous_page?, after, result_size, limit, inverted)
    end

    context 'when after is present' do
      let(:after) { :after }

      it { is_expected.to be true }
    end

    context 'when inverted and result_size == limit' do
      let(:inverted) { true }
      let(:result_size) { 3 }
      let(:limit) { 3 }

      it { is_expected.to be true }
    end
  end

  describe '.next_page?' do
    let(:before) { nil }
    let(:result_size) { nil }
    let(:limit) { nil }
    let(:inverted) { false }

    subject do
      cursor = Connections::CursorConnection.new(Dossier)
      cursor.send(:next_page?, before, result_size, limit, inverted)
    end

    context 'when before is present' do
      let(:before) { :before }

      it { is_expected.to be true }
    end

    context 'when not inverted and result_size == limit' do
      let(:inverted) { false }
      let(:result_size) { 3 }
      let(:limit) { 3 }

      it { is_expected.to be true }
    end
  end
end
