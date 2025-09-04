# frozen_string_literal: true

require "rails_helper"

RSpec.describe LLM::RevisionImproverService do
  let(:procedure) { create(:simple_procedure) }
  let(:llm) { double('llm', chat_parameters: double('params', update: nil)) }

  before do
    allow(LLM::OpenAIClient).to receive(:instance).and_return(llm)
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:write)
  end

  def stub_run_chat(result)
    allow_any_instance_of(described_class).to receive(:run_chat).and_return(result)
  end

  it 'returns normalized operations when nested under operations' do
    json = {
      operations: { destroy: [{ stable_id: 1 }], update: [], add: [] },
      summary: 'ok'
    }.to_json
    stub_run_chat(json)

    result = described_class.new(procedure).suggest!
    expect(result[:destroy]).to eq([{ stable_id: 1 }])
    expect(result[:update]).to eq([])
    expect(result[:add]).to eq([])
    expect(result[:summary]).to eq('ok')
    expect(File).to have_received(:write).at_least(:once)
  end

  it 'accepts flat keys and maps destroy to destroy' do
    json = { destroy: [{ stable_id: 2 }], update: [], add: [], summary: 'ok' }.to_json
    stub_run_chat(json)

    result = described_class.new(procedure).suggest!
    expect(result[:destroy]).to eq([{ stable_id: 2 }])
  end

  it 'raises InvalidOutput for non-JSON output' do
    stub_run_chat('not-json')
    service = described_class.new(procedure)
    expect { service.suggest! }.to raise_error(LLM::RevisionImproverService::Errors::InvalidOutput)
  end
end
