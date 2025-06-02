# frozen_string_literal: true

describe Procedure::PendingRepublishComponent, type: :component do
  subject { render_inline(described_class.new(render_if:, procedure: build(:procedure, id: 1))) }
  let(:page) { subject }
  describe 'render_if' do
    context 'when false' do
      let(:render_if) { false }
      it { expect(page).not_to have_text('Ces modifications ne seront appliquées') }
    end
    context 'when true' do
      let(:render_if) { true }
      it { expect(page).to have_text('Ces modifications ne seront appliquées') }
    end
  end
end
