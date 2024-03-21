import type { SuggestionOptions, SuggestionProps } from '@tiptap/suggestion';
import { z } from 'zod';
import tippy, { type Instance as TippyInstance } from 'tippy.js';
import { matchSorter } from 'match-sorter';

export const tagSchema = z
  .object({ tagLabel: z.string(), tagId: z.string() })
  .transform(({ tagId, tagLabel }) => ({ label: tagLabel, id: tagId }));
export type TagSchema = z.infer<typeof tagSchema>;

class SuggestionMenu {
  #selectedIndex = 0;
  #props: SuggestionProps<TagSchema>;

  #element?: Element;
  #popup?: TippyInstance;

  constructor(props: SuggestionProps<TagSchema>, editorElement: Element) {
    this.#props = props;
    this.render();
    this.init(editorElement);
  }

  init(editorElement: Element) {
    if (!this.#props.clientRect) {
      return;
    }

    this.#popup = tippy(document.body, {
      getReferenceClientRect: () => {
        const domRect = this.#props?.clientRect?.();
        if (!domRect) {
          throw new Error('domRect is null');
        }
        return domRect;
      },
      appendTo: editorElement,
      content: this.#element,
      showOnCreate: true,
      interactive: true,
      trigger: 'manual',
      placement: 'bottom-start'
    });
  }

  update(props: SuggestionProps<TagSchema>) {
    this.#props = props;

    if (!this.#props.clientRect) {
      return;
    }

    this.#popup?.setProps({
      getReferenceClientRect: () => {
        const domRect = props.clientRect?.();
        if (!domRect) {
          throw new Error('domRect is null');
        }
        return domRect;
      }
    });

    this.render();
  }

  onKeyDown(key: string) {
    switch (key) {
      case 'ArrowDown':
        this.down();
        return true;
      case 'ArrowUp':
        this.up();
        return true;
      case 'Escape':
        this.escape();
        return true;
      case 'Enter':
        this.enter();
        return true;
    }
    return false;
  }

  destroy() {
    this.#popup?.destroy();
    this.#element?.remove();
  }

  private render() {
    this.#element ??= this.createMenu();
    const list = this.#element.firstChild as HTMLUListElement;

    const html = this.#props.items
      .map((item, i) => {
        return `<li class="fr-badge fr-badge--sm fr-badge--no-icon${
          i == this.#selectedIndex ? ' fr-badge--info' : ''
        }">${item.label}</li>`;
      })
      .join('');

    this.#element.classList.add('fr-menu__list');
    list.innerHTML = html;
    list.querySelector<HTMLElement>('.selected')?.focus();
  }

  private createMenu() {
    const menu = document.createElement('div');
    const list = document.createElement('ul');
    menu.classList.add('fr-menu');
    list.classList.add('fr-menu__list');
    menu.appendChild(list);

    return menu;
  }

  private up() {
    this.#selectedIndex =
      (this.#selectedIndex + this.#props.items.length - 1) %
      this.#props.items.length;
    this.render();
  }

  private down() {
    this.#selectedIndex = (this.#selectedIndex + 1) % this.#props.items.length;
    this.render();
  }

  private enter() {
    const item = this.#props.items[this.#selectedIndex];

    if (item) {
      this.#props.command(item);
    }
  }

  private escape() {
    this.#popup?.hide();
    this.#selectedIndex = 0;
  }
}

export function createSuggestionMenu(
  tags: TagSchema[],
  editorElement: Element
): Omit<SuggestionOptions<TagSchema>, 'editor'> {
  return {
    char: '@',
    items: ({ query }) => {
      return matchSorter(tags, query, { keys: ['label'] }).slice(0, 6);
    },
    render: () => {
      let menu: SuggestionMenu;

      return {
        onStart: (props) => {
          menu = new SuggestionMenu(props, editorElement);
        },

        onUpdate(props) {
          menu.update(props);
        },

        onKeyDown(props) {
          return menu.onKeyDown(props.event.key);
        },

        onExit() {
          menu.destroy();
        }
      };
    }
  };
}
