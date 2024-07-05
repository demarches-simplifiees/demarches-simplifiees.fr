import type { ReactNode } from 'react';
import { z } from 'zod';

import type { Loader } from './hooks';

export const Item = z.object({
  label: z.string(),
  value: z.string(),
  data: z.any().optional()
});
export type Item = z.infer<typeof Item>;

const ComboBoxPropsSchema = z
  .object({
    id: z.string(),
    className: z.string(),
    name: z.string(),
    label: z.string(),
    description: z.string(),
    isRequired: z.boolean(),
    'aria-label': z.string(),
    'aria-labelledby': z.string(),
    'aria-describedby': z.string(),
    items: z
      .array(Item)
      .or(
        z
          .string()
          .array()
          .transform((items) =>
            items.map<Item>((label) => ({ label, value: label }))
          )
      )
      .or(
        z
          .tuple([z.string(), z.string().or(z.number())])
          .array()
          .transform((items) =>
            items.map<Item>(([label, value]) => ({
              label,
              value: String(value)
            }))
          )
      ),
    formValue: z.enum(['text', 'key']),
    form: z.string(),
    data: z.record(z.string())
  })
  .partial();
export const SingleComboBoxProps = ComboBoxPropsSchema.extend({
  selectedKey: z.string().nullable(),
  emptyFilterKey: z.string()
}).partial();
export const MultiComboBoxProps = ComboBoxPropsSchema.extend({
  selectedKeys: z.string().array(),
  allowsCustomValue: z.boolean(),
  valueSeparator: z.string()
}).partial();
export const RemoteComboBoxProps = ComboBoxPropsSchema.extend({
  selectedKey: z.string().nullable(),
  minimumInputLength: z.number(),
  limit: z.number(),
  allowsCustomValue: z.boolean()
}).partial();
export type SingleComboBoxProps = z.infer<typeof SingleComboBoxProps> & {
  children?: ReactNode;
};
export type MultiComboBoxProps = z.infer<typeof MultiComboBoxProps>;
export type RemoteComboBoxProps = z.infer<typeof RemoteComboBoxProps> & {
  children?: ReactNode;
  loader: Loader | string;
  onChange?: (item: Item | null) => void;
};
