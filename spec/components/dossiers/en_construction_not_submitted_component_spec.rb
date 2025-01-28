# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dossiers::EnConstructionNotSubmittedComponent, type: :component do
  let(:dossier) { create(:dossier, :en_construction) }

  subject {
    render_inline(described_class.new(dossier:, user: dossier.user)).to_html
  }

  it { expect(subject).to be_empty }
end
