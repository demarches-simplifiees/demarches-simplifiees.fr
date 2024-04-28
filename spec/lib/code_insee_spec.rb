# frozen_string_literal: true

describe CodeInsee do
  it 'converts to departement' do
    expect(CodeInsee.new('75002').to_departement).to eq('75')
    expect(CodeInsee.new('2B033').to_departement).to eq('2B')
    expect(CodeInsee.new('01345').to_departement).to eq('01')
    expect(CodeInsee.new('97100').to_departement).to eq('971')
    expect(CodeInsee.new('98735').to_departement).to eq('987')
  end
end
