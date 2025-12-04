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
              { 'function' => { 'name' => 'improve_label', 'arguments' => '{"update":{"stable_id":1,"libelle":"Libellé"}}' } },
            ],
          },
        },
      ],
    }
    response = double('response', raw_response: raw)
    client = double('client', chat: response)

    tool_calls, usage = described_class.new(client: client, model: 'openai/gpt-5').call(messages: messages, tools: tools)

    expect(tool_calls.size).to eq(1)
    expect(tool_calls.first).to include(name: 'improve_label')
    expect(tool_calls.first[:arguments]).to eq({ 'update' => { 'stable_id' => 1, 'libelle' => 'Libellé' } })
  end

  it 'returns empty when no tool_calls are present' do
    raw = { 'choices' => [{ 'message' => { 'tool_calls' => [] } }] }
    response = double('response', raw_response: raw)
    client = double('client', chat: response)

    tool_calls, usage = described_class.new(client: client).call(messages: messages, tools: tools)
    expect(tool_calls).to eq([])
  end

  it 'publishes llm.call notification with success payload' do
    raw = {
      'choices' => [{ 'message' => { 'tool_calls' => [] } }],
      'usage' => { 'prompt_tokens' => 10, 'completion_tokens' => 5 },
      'status' => 200,
    }
    response = double('response', raw_response: raw)
    client = double('client', chat: response)

    events = nil
    called = false
    subscription = ActiveSupport::Notifications.subscribe('llm.call') do |_name, start, finish, _id, payload|
      duration = finish - start
      event_type = payload[:exception] ? "llm_call_error" : "llm_call_success"

      events = payload.merge({
        event: event_type,
        duration_ms: (duration * 1000).round,
        error_class: payload[:exception]&.class&.name,
        error_message: payload[:exception]&.message,
      }).compact
      called = true
    end

    described_class.new(client: client, model: 'gpt-4').call(
      messages: messages,
      tools: tools,
      procedure_id: 123,
      rule: 'improve_label',
      action: 'nightly',
      user_id: 456
    )

    ActiveSupport::Notifications.unsubscribe(subscription)

    expect(called).to be true
    expect(events[:event]).to eq('llm_call_success')
    expect(events[:procedure_id]).to eq(123)
    expect(events[:rule]).to eq('improve_label')
    expect(events[:action]).to eq('nightly')
    expect(events[:user_id]).to eq(456)
    expect(events[:model]).to eq('gpt-4')
    expect(events[:prompt_tokens]).to eq(10)
    expect(events[:completion_tokens]).to eq(5)
    expect(events[:status]).to eq(200)
    expect(events[:duration_ms]).to be_a(Integer)
  end

  it 'publishes llm.call notification with error payload' do
    client = double('client')
    allow(client).to receive(:chat).and_raise(StandardError.new('API error'))

    events = nil
    called = false
    subscription = ActiveSupport::Notifications.subscribe('llm.call') do |_name, start, finish, _id, payload|
      duration = finish - start
      event_type = payload[:exception] ? "llm_call_error" : "llm_call_success"

      events = payload.merge({
        event: event_type,
        duration_ms: (duration * 1000).round,
        error_class: payload[:exception]&.class&.name,
        error_message: payload[:exception]&.message,
      }).compact
      called = true
    end

    expect {
      described_class.new(client: client).call(
        messages: messages,
        tools: tools,
        procedure_id: 123,
        rule: 'improve_label',
        action: 'nightly',
        user_id: 456
      )
    }.to raise_error(StandardError, 'API error')

    ActiveSupport::Notifications.unsubscribe(subscription)

    expect(called).to be true
    expect(events[:event]).to eq('llm_call_error')
    expect(events[:procedure_id]).to eq(123)
    expect(events[:rule]).to eq('improve_label')
    expect(events[:action]).to eq('nightly')
    expect(events[:user_id]).to eq(456)
    expect(events[:error_class]).to eq('StandardError')
    expect(events[:error_message]).to eq("API error")
    expect(events[:duration_ms]).to be_a(Integer)
  end
end
