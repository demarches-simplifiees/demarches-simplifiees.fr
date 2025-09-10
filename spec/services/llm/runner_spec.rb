# frozen_string_literal: true

require 'rails_helper'

describe LLM::Runner do
  let(:messages) { [{ role: 'user', content: 'test' }] }
  let(:tools) { [{ type: 'function', function: { name: 'improve_label', parameters: { type: 'object', properties: {} } } }] }

  it 'parses tool_calls and returns normalized events' do
    raw = {
      'choices' => [
        {
          'message' => {
            'tool_calls' => [
              { 'function' => { 'name' => 'improve_label', 'arguments' => '{"update":{"stable_id":1,"libelle":"Libellé"}}' } }
            ]
          }
        }
      ]
    }
    response = double('response', raw_response: raw)
    client = double('client', chat: response)

    events = described_class.new(client: client, model: 'openai/gpt-5').call(messages: messages, tools: tools)

    expect(events.size).to eq(1)
    expect(events.first).to include(name: 'improve_label')
    expect(events.first[:arguments]).to eq({ 'update' => { 'stable_id' => 1, 'libelle' => 'Libellé' } })
  end

  it 'returns empty when no tool_calls are present' do
    raw = { 'choices' => [{ 'message' => { 'tool_calls' => [] } }] }
    response = double('response', raw_response: raw)
    client = double('client', chat: response)

    events = described_class.new(client: client).call(messages: messages, tools: tools)
    expect(events).to eq([])
  end

  it 'handles malformed arguments gracefully' do
    raw = {
      'model' => 'openai/gpt-5',
      'choices' => [
        {
          'message' => {
            'tool_calls' => [
              { 'function' => { 'name' => 'improve_label', 'arguments' => 'not json' } }
            ]
          }
        }
      ]
    }
    response = double('response', raw_response: raw)
    client = double('client', chat: response)

    events = described_class.new(client: client).call(messages: messages, tools: tools)
    expect(events.first[:arguments]).to eq({})
  end
end
