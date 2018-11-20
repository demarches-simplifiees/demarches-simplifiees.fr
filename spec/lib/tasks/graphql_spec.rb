require 'spec_helper'

describe 'graphql' do
  let(:current_defn) { Api::V2::Schema.to_definition }
  let(:printout_defn) { File.read(Rails.root.join('app', 'graphql', 'schema.graphql')) }

  it "update the printed schema with `bin/rake graphql:dump_schema`" do
    expect("#{current_defn}\n").to eq(printout_defn)
  end
end
