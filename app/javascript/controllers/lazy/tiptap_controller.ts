import { Editor } from '@tiptap/core';
import { isButtonElement, isHTMLElement } from '@coldwired/utils';
import * as s from 'superstruct';

import { ApplicationController } from '../application_controller';
import { getAction } from '../../shared/tiptap/actions';
import { tagSchema, type TagSchema } from '../../shared/tiptap/tags';
import { createEditor } from '../../shared/tiptap/editor';

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
      const tag = s.create(event.target.dataset, tagSchema);
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
      return s.create(JSON.parse(value), jsonContentSchema);
    }
  }

  private get tags(): TagSchema[] {
    return this.tagTargets.map((tag) => s.create(tag.dataset, tagSchema));
  }

  private get menuButtons() {
    return this.buttonTargets.map(
      (menuButton) => menuButton.dataset.tiptapAction as string
    );
  }
}

const Attrs = s.record(s.string(), s.any());
const Marks = s.array(
  s.type({
    type: s.string(),
    attrs: s.optional(Attrs)
  })
);
type JSONContent = {
  type?: string;
  text?: string;
  attrs?: s.Infer<typeof Attrs>;
  marks?: s.Infer<typeof Marks>;
  content?: JSONContent[];
};
const jsonContentSchema: s.Describe<JSONContent> = s.type({
  type: s.optional(s.string()),
  text: s.optional(s.string()),
  attrs: s.optional(Attrs),
  marks: s.optional(Marks),
  content: s.lazy(() => s.optional(s.array(jsonContentSchema)))
});
