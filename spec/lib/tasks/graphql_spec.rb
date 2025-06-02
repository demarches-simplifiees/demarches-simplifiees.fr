# frozen_string_literal: true

describe 'graphql' do
  let(:current_defn) { API::V2::Schema.to_definition }
  let(:printout_defn) { Rails.root.join('app', 'graphql', 'schema.graphql').read }

  it "update the printed schema with `bin/rake graphql:schema:idl`" do
    result = GraphQL::SchemaComparator.compare(current_defn, printout_defn)
    expect(result.identical?).to be_truthy
  end
end
