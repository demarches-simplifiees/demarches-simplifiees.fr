import { ApplicationController } from './application_controller';
import { Editor } from '@tiptap/core';
import StarterKit from '@tiptap/starter-kit';
import Mention from '@tiptap/extension-mention';
import tippy, { type Instance } from 'tippy.js';
import { httpRequest } from '@utils';

export class AttestationController extends ApplicationController {
  static values = {
    tags: Array,
    url: String
  };

  static targets = ['editor', 'bold'];

  declare readonly tagsValue: string[];
  declare readonly urlValue: string;
  declare editor: Editor;
  declare editorTarget: HTMLElement;
  declare boldTarget: HTMLButtonElement;

  connect() {
    const conf = {
      element: this.editorTarget,
      editorProps: {
        attributes: {
          class: 'fr-input'
        }
      },
      extensions: [
        StarterKit,
        Mention.configure({
          HTMLAttributes: {
            class: 'mention'
          },
          suggestion: {
            items: ({ query }) => {
              return this.tagsValue
                .filter((item) =>
                  item.toLowerCase().startsWith(query.toLowerCase())
                )
                .slice(0, 5);
            },

            render: () => {
              let popup: Instance;
              let div: HTMLElement;
              let selectedIndex = 0;
              let items: string[];
              let command: (props: object) => void;

              const makeList = () => {
                return items
                  .map((item, i) => {
                    if (i == selectedIndex) {
                      return `<li class='selected'>${item}</li>`;
                    } else {
                      return `<li>${item}</li>`;
                    }
                  })
                  .join('');
              };

              return {
                onStart: (props) => {
                  items = props.items;
                  command = props.command;

                  div = document.createElement('UL');
                  div.innerHTML = makeList();

                  if (!props.clientRect) {
                    return;
                  }

                  popup = tippy(document.body, {
                    getReferenceClientRect: () => {
                      const domrect = props.clientRect?.();
                      if (!domrect) {
                        throw new Error('No client rect');
                      }
                      return domrect;
                    },
                    appendTo: () => this.element,
                    content: div,
                    showOnCreate: true,
                    interactive: true,
                    trigger: 'manual',
                    placement: 'bottom-start'
                  });
                },

                onUpdate(props) {
                  command = props.command;
                  items = props.items;

                  div.innerHTML = makeList();

                  if (!props.clientRect) {
                    return;
                  }

                  popup.setProps({
                    getReferenceClientRect: () => {
                      const domrect = props.clientRect?.();
                      if (!domrect) {
                        throw new Error('No client rect');
                      }
                      return domrect;
                    }
                  });
                },

                onKeyDown(props) {
                  if (props.event.key === 'Escape') {
                    popup.hide();

                    return true;
                  }

                  if (props.event.key === 'ArrowDown') {
                    selectedIndex = (selectedIndex + 1) % items.length;
                    div.innerHTML = makeList();
                    return true;
                  }

                  if (props.event.key === 'ArrowUp') {
                    selectedIndex =
                      (selectedIndex + items.length - 1) % items.length;
                    div.innerHTML = makeList();
                    return true;
                  }

                  if (props.event.key === 'Enter') {
                    const item = items[selectedIndex];

                    if (item) {
                      command({ id: item });
                    }
                    return true;
                  }

                  return false;
                },

                onExit() {
                  popup.destroy();
                  div.remove();
                }
              };
            }
          }
        })
      ],
      content:
        '<p>La situation de M. <span data-type="mention" data-id="nom"></span> dont la demande de logement social</p>'
    };

    this.editor = new Editor(conf);

    this.editor.on('transaction', () => {
      this.boldTarget.disabled = !this.editor
        .can()
        .chain()
        .focus()
        .toggleBold()
        .run();

      if (this.editor.isActive('bold')) {
        this.boldTarget.classList.add('fr-btn--secondary');
      } else {
        this.boldTarget.classList.remove('fr-btn--secondary');
      }
    });
  }

  bold() {
    this.editor.chain().focus().toggleBold().run();
  }

  send() {
    const json = this.editor.getJSON();
    httpRequest(this.urlValue, { method: 'put', json }).json();
  }
}
