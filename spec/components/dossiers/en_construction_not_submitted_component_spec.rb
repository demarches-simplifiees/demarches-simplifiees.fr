# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dossiers::EnConstructionNotSubmittedComponent, type: :component do
  let(:dossier) { create(:dossier, :en_construction) }

  subject {
    render_inline(described_class.new(dossier:, user: dossier.user)).to_html
  }

  context "without fork" do
    it { expect(subject).to be_empty }
  end

  context "with a fork" do
    let!(:fork) { dossier.find_or_create_editing_fork(dossier.user) }

    it "render nothing without changes" do
      expect(subject).to be_empty
    end

    context "with changes" do
      before { fork.champs_public.first.update(value: "new value") }

      it "inform user" do
        expect(subject).to include("Des modifications n’ont pas encore été déposées")
      end
    end
  end
end
