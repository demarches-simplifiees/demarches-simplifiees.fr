# frozen_string_literal: true

require 'fileutils'
require 'langchain'
require 'json_schemer'

module LLM
  class RevisionImproverService
    JSON_OPS_SCHEMA = JSON.parse(
      Rails.root.join('config/llm/revision_improver_operations_json_schema.json').read
    ).freeze

    attr_reader :llm, :procedure, :logger, :clock
    attr_accessor :now

    module Errors
      class InvalidOutput < StandardError; end
      class Unavailable < StandardError; end
    end

    def initialize(procedure, llm: OpenAIClient.instance, logger: Rails.logger, clock: -> { Time.zone.now.to_i })
      @procedure = procedure
      @llm = llm
      @logger = logger
      @clock = clock
    end

    # Optional analysis phase. Returns raw assistant content (String).
    def analyze!
      llm.chat_parameters.update(
        temperature: { default: 1.0 },
        repetition_penalty: { default: 0 },
        max_tokens: { default: 4096 },
        response_format: { default: { type: 'json_object' } }
      )
      messages = [system_message, *messages_for_analyze]
      content = run_chat(messages)
      backup('analysis', content)
      content
    end

    # Backward-compat shim
    def analyze
      analyze!
    end

    # Main entry point returning normalized operations:
    # { destroy: [], update: [], add: [], summary: "..." }
    def suggest!(analysis: nil)
      llm.chat_parameters.update(temperature: { default: 0.1 }, repetition_penalty: { default: 0 }, max_tokens: { default: 4096 })
      messages = [system_message, *messages_for_suggest(analysis)]
      content = run_chat(messages)
      backup('suggest', content)

      json = parse_json!(content)
      validate_ops!(json)
      normalize_ops(json)
    rescue Errors::InvalidOutput
      raise
    rescue => e
      logger.warn("[LLM] suggest! failed: #{e.class}: #{e.message}")
      raise
    end

    # Backward-compat wrapper for callers expecting {operations:, summary:}
    def suggest
      ops = suggest!(analysis: @injected_analysis)
      { operations: { destroy: ops[:destroy], update: ops[:update], add: ops[:add] }, summary: ops[:summary] }
    end

    # Backward-compat: allow injecting a precomputed analysis
    def insert_analysis(analysis)
      @injected_analysis = analysis
    end

    private

    def run_chat(messages)
      assistant = Langchain::Assistant.new(llm:)
      messages.each { |m| assistant.add_message(**m) }
      assistant.run!
      assistant.messages.last.content.to_s
    end

    def system_message
      { role: 'system', content: system_prompt }
    end

    def messages_for_analyze
      [
        { role: 'user', content: current_schema_prompt },
        { role: 'user', content: analyze_prompt },
      ]
    end

    def messages_for_suggest(analysis)
      msgs = [
        { role: 'user', content: current_schema_prompt },
        { role: 'user', content: format(restructure_prompt, json_schema: JSON.dump(JSON_OPS_SCHEMA)) },
      ]
      analysis ? [{ role: 'assistant', content: analysis }] + msgs : msgs
    end

    def parse_json!(content)
      s = content.to_s.strip
      # Strip Markdown code fences if present, optionally labeled as json
      if s.start_with?("```")
        s = s.sub(/\A```(?:json)?\s*/i, "").sub(/```+\s*\z/, "").strip
      else
        # Or extract the first fenced JSON block
        if (m = s.match(/```(?:json)?\s*(\{.*\})\s*```/im))
          s = m[1].strip
        end
      end

      begin
        JSON.parse(s)
      rescue JSON::ParserError
        # Fallback: try parsing the largest JSON-looking object in the text
        if s.include?("{") && s.include?("}")
          inner = s[s.index('{')..s.rindex('}')]
          JSON.parse(inner)
        else
          raise Errors::InvalidOutput, 'Non JSON content from LLM'
        end
      end
    rescue JSON::ParserError
      raise Errors::InvalidOutput, 'Non JSON content from LLM'
    end

    def validate_ops!(json)
      # Accept both shapes: {operations:{...}, summary:""} or flat keys {delete/update/add/summary}
      candidate = if json.key?('operations')
        json
      else
        { 'operations' => json.slice('destroy', 'update', 'add'), 'summary' => json['summary'] }
      end

      schemer = JSONSchemer.schema(JSON_OPS_SCHEMA)
      errors = schemer.validate(candidate).to_a
      raise Errors::InvalidOutput, errors.first&.dig('details') if errors.any?
    end

    def normalize_ops(json)
      ops = json['operations'] || json
      {
        destroy: Array(ops['destroy']).map { |h| deep_symbolize(h) },
        update: Array(ops['update']).map { |h| deep_symbolize(h) },
        add: Array(ops['add']).map { |h| deep_symbolize(h) },
        summary: json['summary'].to_s,
      }
    end

    def deep_symbolize(obj)
      case obj
      when Hash
        obj.transform_keys { |k| k.to_sym rescue k }.transform_values do |v|
          deep_symbolize(v)
        end
      when Array
        obj.map { |v| deep_symbolize(v) }
      else
        obj
      end
    end

    def current_schema_prompt
      template = <<~PROMPT
        Here is the form schema you need to analyze:

        <form_schema>
          %<schema>s
        </form_schema>

        Here's the administrative procedure you'll be working on:
        <demarche_libelle>
          %<libelle>s
        </demarche_libelle>

        The applicant's email address, civility, first name, and last name are already known to administration and should not be requested again.
      PROMPT

      format(template, libelle: procedure.libelle, schema: procedure.published_revision.schema_to_llm.to_json)
    end

    def system_prompt
      <<~PROMPT
        You are an AI assistant specialized in optimizing online forms for French administrative procedures.
        Your task is to analyze and improve a given form schema, making it more user-friendly,
        efficient, and compliant with official recommendations.
      PROMPT
    end

    def analyze_prompt
      <<~PROMPT
        Read carefully these guidelines:
          1. Field Types: Use the appropriate field type from the following list:
            - header_section: For organizing form sections (no user input)
            - repetition: For repeatable blocks of children fields. User can repeat children fields as many times as he wants.
            - explication: For providing context or instructions (no user input)
            - civilite: For selecting "Madame" or "Monsieur". Administration already knows civilite of user
            - email: For email addresses. Administration already knows email of user
            - phone: For phone numbers
            - address: For postal addresses (auto-completed with additional info: commune name and codes, code postal, departement name and code)
            - communes: For selecting French communes (auto-completed with additional info: code, code postal, departement name and code)
            - departments: For selecting French departments
            - text: For short text inputs
            - textarea: For longer text inputs
            - integer_number: For whole numbers
            - decimal_number: For numbers with decimals
            - date: For date selection
            - piece_justificative: For document uploads. Do not wrap in a repetition because it supports multiple documents
            - titre_identite: For secure identity document uploads
            - checkbox: For single checkboxes
            - yes_no: For yes/no questions
            - drop_down_list: For single-choice selections. Choices are configured by administration separately
            - multiple_drop_down_list: For multiple-choice selections. Choices are configured by administration separately

          2. Labeling and Descriptions:
            - Use proper capitalization in labels and descriptions (ie. not in uppercase). This is crucial.
            - Use consistent, plain language throughout the form
            - Make labels clear and understandable for all users
            - Avoid abbreviations, acronyms, and technical jargon
            - Maintain consistent pronouns ("Vous" or "Nous") when addressing users
            - Replace negative constructions with positive, action-oriented statements
            - Keep sentences short with one idea per sentence
            - Structure all headings and labels uniformly
            - Provide descriptions only when necessary to clarify the field's purpose or requirements. Descriptions must not be redundant to labels and must not contain formatting exemples or choices.
            - Avoid trivial or redundant descriptions with labels. They must be really useful.
            - Write in active voice using present tense
            - Start conditional statements with the condition
            - Use standardized field labels (e.g., "Adresse email" not "Adresse de courrier électronique")
            - Specify document requirements clearly (format, validity, original vs copy)

          3. Form Structure:
            - Place essential fields first, following user-centric logic
            - Remove any fields asking for information already known to the administration. This is absolutely crucial.
            - Minimize the number of required documents
            - Add header sections to structure the fields with appropriate level if necessary (level starts at 1)
            - Apply visibility conditions to dynamically show/hide a field based on another field's exact choice or value. When a field is hidden by its visibility condition, its mandatory rule will be ignored
            - Use checkboxes for consent fields
            - Consider information automatically retrieved by certain field types (e.g., address, communes) to avoid redundant questions. This is your main goal.

          4. Mandatory Fields:
            - By default, all input fields are considered mandatory (mandatory = true)
            - Explicitly set mandatory = false for optional fields

        Please analyze the form schema and provide recommendations for improvements. Follow these steps:

        1. Analyze the overall form structure.
        2. For each field in the form:
            a. Determine carefully if the field should be deleted, updated, or kept as is
            b. Delete if:
              - Identifed as redundant with another field
              - Data is already known by the administration (e.g., email, first name of user, postal code when there's an address field)
              - the field should be part of a `repetition` structure instead
            c. Update if:
              - the label or description is unclear or inappropriate
              - the label is in uppercase : update field with a proper case
              - field's visibility should be conditioned by the value of a previous field
              - field type is not appropriate
              - Ensure compliance with guidelines
        3. Identify where header sections could be added to improve the form structure.
        4. Review official recommendations for French administrative forms and note any potential compliance issues

        Structure your analysis in a <analysis> tags.
        It's OK for this section to be quite long.
      PROMPT
    end

    def restructure_prompt
      <<~PROMPT
        Based on your previous analysis, structure ALL fields in a JSON format following this schema:
        %<json_schema>s

        CRITICAL RULES for field processing:
        1. You MUST include ALL original fields in your response, distributed between:
           - "destroy" category
           - "update" category

        2. When a field is added to a repetition structure:
           - You MUST destroy ALL original standalone versions
           - This deletion MUST be documented in the "destroy" category
           - Use justification: "Remplacé par un bloc répétable dynamique"

        3. For each field in "update" category:
           - If modifications needed: specify only the changing attributes
           - Update label with a proper case
           - If no modifications needed: skip justification
           - But ALWAYS list the field

        Remember previous analysis guidelines:
        - Keep relevant repetition structures identified
        - Preserve planned improvements to descriptions
        - Follow French administrative standards
        - Keep identified redundancy removals
        - Answer labels, descriptions, summary, justification in french.

        Output requirements:
        - Return ONLY raw JSON. No markdown, no code fences, no commentary.
        - Do not wrap the JSON in ```json ... ``` blocks.

        Response structure:
        {
          "add": [
            - ALL added fields
          ],
          "destroy": [
            - ALL destroyed fields, including all those moved to repetition
            - Clear justification for each deletion
          ],
          "update": [
            - ALL remaining fields, including unchanged ones
            - For modified fields: only changed attributes and a justification
          ],
          "summary": {
            - Brief French summary of implemented changes
            - Focus on structural improvements
            - MUST be a string, not an object
          }
        }
      PROMPT
    end

    def backup(part, content)
      ts = now || clock.call
      path = Rails.root.join('tmp/llm', "procedure_#{procedure.id}_#{ts}_#{part}.txt")
      FileUtils.mkdir_p(path.dirname)
      File.write(path, content.to_s)
    end
  end
end
