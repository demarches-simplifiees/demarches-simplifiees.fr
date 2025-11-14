# frozen_string_literal: true

describe DataSources::AdresseController, type: :controller do
  describe "#clean_query" do
    subject(:clean_query) { controller.send(:clean_query, input) }

    context "when the query is valid but needs formatting" do
      let(:input) { "   123    rue  de   Paris   " }

      it "strips, collapses spaces, and returns the sanitized query" do
        expect(clean_query).to eq("123 rue de Paris")
      end
    end

    context "when the query starts with non alphanumeric characters" do
      let(:input) { "###Rue de la Paix" }

      it "removes the leading characters before returning" do
        expect(clean_query).to eq("Rue de la Paix")
      end
    end

    context "when the sanitized query is shorter than 3 characters" do
      let(:input) { "  a " }

      it { is_expected.to be_nil }
    end

    context "when the sanitized query exceeds 200 characters" do
      let(:input) { "a" * 201 }

      it "returns the first 200 characters" do
        expect(clean_query).to eq("a" * 200)
      end
    end
  end
end
