import { z } from 'zod';
import { zodToJsonSchema } from 'zod-to-json-schema';
import { PromptTemplate } from 'langchain/prompts';
import { OllamaFunctions } from 'langchain/experimental/chat_models/ollama_functions';
import { JsonOutputFunctionsParser } from 'langchain/output_parsers';

import { ApplicationController } from './application_controller';

// Ref: https://github.com/langchain-ai/langchainjs/blob/main/langchain/src/chat_models/ollama.ts
const model = new OllamaFunctions({
  model: 'deepseek-coder:6.7b',
  temperature: 0.0
  // baseUrl: '127.0.0.1:11434'
});

const today = new Date().toLocaleDateString('en-US', {
  weekday: 'long',
  month: 'long',
  day: 'numeric',
  year: 'numeric'
});

const EXTRACTION_TEMPLATE = `
Extract and save all relevant dossiers filters with their properties expressed in the following message from an agent.

All dates are in YYYY-MM-DD format. When an interval is mentionned, like a full year, month or week, or between two dates, convert the interval into appropriate before/after filters and dates.
For example when interval is "june 2023", convert with filters "after 2023-06-01" and "before 2023-07-01".
When extracting a family name, remove the title like Mr, Mme, Madame, etc…
Boolean-like values (no, yes, true, false, etc) of champs are converted into booleans values.
A dossier is made of a list champs, think about key-value pair. Sometimes filters apply to theses champs, with properties "champ", "value" and an optional "operator".

Today is ${today}.

Do NOT make up or guess ANY extra information. Only extract what exactly is in the filter message. Do not express updated dates filters unless explicity requested.

Message:
{input}
`;

const prompt = PromptTemplate.fromTemplate(EXTRACTION_TEMPLATE);

const filtersSchema = z.object({
  filters: z.array(
    z.union([
      z.object({
        updated_after: z.string().optional()
      }),

      z.object({
        updated_before: z.string().optional()
      }),

      z.object({
        updated_on: z.string().optional()
      }),

      z.object({
        states: z
          .array(
            z.enum([
              'en_construction',
              'en_instruction',
              'accepté',
              'refusé',
              'sans_suite'
            ])
          )
          .optional()
      }),

      z.object({
        depositer_name: z.string().optional()
      }),

      z.object({
        depositer_email: z.string().optional()
      }),

      z.object({
        deposited_after: z.string().optional()
      }),

      z.object({
        deposited_before: z.string().optional()
      }),

      z.object({
        deposited_on: z.string().optional()
      }),

      z.object({
        champ: z.union([
          z.literal('commune'),
          z.literal('montant de la subvention demandée'),
          z.literal("nom de l'association"),
          z.literal('Age du contractant'),
          z.literal("J'accepte les conditions d'usage et de coutume d'un LLM")
        ]),
        value: z.union([z.string(), z.number(), z.boolean()]),
        operator: z.enum(['eq', 'neq', 'lte', 'lt', 'gte', 'gt']).optional()
      })
    ])
  )
});

const functionSchema = [
  {
    name: 'apply_filters',
    description: 'Dossiers filters list',
    parameters: {
      type: 'object',
      properties: zodToJsonSchema(filtersSchema)
    }
  }
];

// console.log('functionsSchema', JSON.stringify(functionSchema, null, 2));

const chain = prompt.pipe(
  model
    .bind({
      functions: functionSchema,
      function_call: { name: 'apply_filters' }
    })
    .pipe(new JsonOutputFunctionsParser())
);

export class LangChainInstructeursFiltersController extends ApplicationController {
  static targets = ['prompt', 'result'];

  declare readonly promptTarget: HTMLInputElement;
  declare readonly resultTarget: HTMLPreElement;

  connect() {
    this.on(this.promptTarget, 'blur', () => {
      this._analyze(this.promptTarget.value);
    });
  }

  async _analyze(prompt: string) {
    if (!prompt) {
      return;
    }

    const spinner = document.createElement('div');
    spinner.classList.add('spinner', 'spinner-removable');
    this.resultTarget.replaceChildren(spinner);

    try {
      const result = await chain.invoke({ input: prompt });

      this.resultTarget.innerHTML = JSON.stringify(result, null, 2);
    } catch (e) {
      console.error(e);
      this.resultTarget.innerHTML = `Oops: ${e}`;
    }
  }
}
