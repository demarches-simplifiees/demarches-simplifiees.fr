import { Editor, type JSONContent } from '@tiptap/core';
import { isButtonElement, isHTMLElement } from '@coldwired/utils';
import { z } from 'zod';

import { ApplicationController } from './application_controller';
import { getAction } from '../shared/tiptap/actions';
import { tagSchema, type TagSchema } from '../shared/tiptap/tags';
import { createEditor } from '../shared/tiptap/editor';

export class TiptapController extends ApplicationController {
  static targets = ['editor', 'input', 'button', 'tag'];
  static values = {
    insertAfterTag: { type: String, default: '' }
  };

  declare editorTarget: Element;
  declare inputTarget: HTMLInputElement;
  declare buttonTargets: HTMLButtonElement[];
  declare tagTargets: HTMLElement[];
  declare insertAfterTagValue: string;

  #initializing = true;
  #editor?: Editor;

  connect(): void {
    this.#editor = createEditor({
      editorElement: this.editorTarget,
      content: this.content,
      tags: this.tags,
      buttons: this.menuButtons,
      onChange: ({ editor }) => {
        for (const button of this.buttonTargets) {
          const action = getAction(editor, button);
          button.classList.toggle('fr-btn--secondary', !action.isActive());
          button.disabled = action.isDisabled();
        }

        const previousValue = this.inputTarget.value;
        const value = JSON.stringify(editor.getJSON());
        this.inputTarget.value = value;

        // Dispatch input event only if the value has changed and not during initialization
        if (this.#initializing) {
          this.#initializing = false;
        } else if (value != previousValue) {
          this.dispatch('input', { target: this.inputTarget, prefix: '' });
        }
      }
    });
  }

  disconnect(): void {
    this.#editor?.destroy();
  }

  menuButton(event: MouseEvent) {
    if (this.#editor && isButtonElement(event.target)) {
      getAction(this.#editor, event.target).run();
    }
  }

  insertTag(event: MouseEvent) {
    if (this.#editor && isHTMLElement(event.target)) {
      const tag = tagSchema.parse(event.target.dataset);
      const editor = this.#editor
        .chain()
        .focus()
        .insertContent({ type: 'mention', attrs: tag });

      if (this.insertAfterTagValue != '') {
        editor.insertContent({ type: 'text', text: this.insertAfterTagValue });
      }
      editor.run();
    }
  }

  private get content() {
    const value = this.inputTarget.value;
    if (value) {
      return jsonContentSchema.parse(JSON.parse(value));
    }
  }

  private get tags(): TagSchema[] {
    return this.tagTargets.map((tag) => tagSchema.parse(tag.dataset));
  }

  private get menuButtons() {
    return this.buttonTargets.map(
      (menuButton) => menuButton.dataset.tiptapAction as string
    );
  }
}

const jsonContentSchema: z.ZodType<JSONContent> = z.object({
  type: z.string().optional(),
  text: z.string().optional(),
  attrs: z.record(z.any()).optional(),
  marks: z
    .object({ type: z.string(), attrs: z.record(z.any()).optional() })
    .array()
    .optional(),
  content: z.lazy(() => z.array(jsonContentSchema).optional())
});
