import { Editor } from '@tiptap/core';
import { z } from 'zod';

type EditorAction = {
  run(): void;
  isActive(): boolean;
  isDisabled(): boolean;
};

export function getAction(
  editor: Editor,
  button: HTMLButtonElement
): EditorAction {
  return tiptapActionSchema.parse(button.dataset)(editor);
}

const EDITOR_ACTIONS: Record<string, (editor: Editor) => EditorAction> = {
  title: (editor) => ({
    run: () => editor.chain().focus(),
    isActive: () => editor.isActive('title'),
    isDisabled: () => !editor.isActive('title')
  }),
  heading2: (editor) => ({
    run: () => editor.chain().focus().toggleHeading({ level: 2 }).run(),
    isActive: () => editor.isActive('heading', { level: 2 }),
    isDisabled: () =>
      editor.isActive('title') ||
      editor.isActive('header') ||
      editor.isActive('footer')
  }),
  heading3: (editor) => ({
    run: () => editor.chain().focus().toggleHeading({ level: 3 }).run(),
    isActive: () => editor.isActive('heading', { level: 3 }),
    isDisabled: () =>
      editor.isActive('title') ||
      editor.isActive('header') ||
      editor.isActive('footer')
  }),
  bold: (editor) => ({
    run: () => editor.chain().focus().toggleBold().run(),
    isActive: () => editor.isActive('bold'),
    isDisabled: () => editor.isActive('heading') || editor.isActive('title')
  }),
  italic: (editor) => ({
    run: () => editor.chain().focus().toggleItalic().run(),
    isActive: () => editor.isActive('italic'),
    isDisabled: () => false
  }),
  underline: (editor) => ({
    run: () => editor.chain().focus().toggleUnderline().run(),
    isActive: () => editor.isActive('underline'),
    isDisabled: () => false
  }),
  strike: (editor) => ({
    run: () => editor.chain().focus().toggleStrike().run(),
    isActive: () => editor.isActive('strike'),
    isDisabled: () => editor.isActive('heading') || editor.isActive('title')
  }),
  highlight: (editor) => ({
    run: () => editor.chain().focus().toggleHighlight().run(),
    isActive: () => editor.isActive('highlight'),
    isDisabled: () => editor.isActive('heading') || editor.isActive('title')
  }),
  bulletList: (editor) => ({
    run: () => editor.chain().focus().toggleBulletList().run(),
    isActive: () => editor.isActive('bulletList'),
    isDisabled: () =>
      editor.isActive('title') ||
      editor.isActive('header') ||
      editor.isActive('footer')
  }),
  orderedList: (editor) => ({
    run: () => editor.chain().focus().toggleOrderedList().run(),
    isActive: () => editor.isActive('orderedList'),
    isDisabled: () =>
      editor.isActive('title') ||
      editor.isActive('header') ||
      editor.isActive('footer')
  }),
  left: (editor) => ({
    run: () => editor.chain().focus().setTextAlign('left').run(),
    isActive: () => editor.isActive({ textAlign: 'left' }),
    isDisabled: () => false
  }),
  center: (editor) => ({
    run: () => editor.chain().focus().setTextAlign('center').run(),
    isActive: () => editor.isActive({ textAlign: 'center' }),
    isDisabled: () => false
  }),
  right: (editor) => ({
    run: () => editor.chain().focus().setTextAlign('right').run(),
    isActive: () => editor.isActive({ textAlign: 'right' }),
    isDisabled: () => false
  }),
  justify: (editor) => ({
    run: () => editor.chain().focus().setTextAlign('justify').run(),
    isActive: () => editor.isActive({ textAlign: 'justify' }),
    isDisabled: () => false
  }),
  undo: (editor) => ({
    run: () => editor.chain().focus().undo().run(),
    isActive: () => false,
    isDisabled: () => !editor.can().chain().focus().undo().run()
  }),
  redo: (editor) => ({
    run: () => editor.chain().focus().redo().run(),
    isActive: () => false,
    isDisabled: () => !editor.can().chain().focus().redo().run()
  })
};

const tiptapActionSchema = z
  .object({
    tiptapAction: z.enum(Object.keys(EDITOR_ACTIONS) as [string, ...string[]])
  })
  .transform(({ tiptapAction }) => EDITOR_ACTIONS[tiptapAction]);
