import type { ListBoxItemProps } from 'react-aria-components';
import {
  ComboBox as AriaComboBox,
  ListBox,
  ListBoxItem,
  Popover,
  Input,
  Label,
  Text,
  Button,
  TagGroup,
  TagList,
  Tag,
  Virtualizer,
  ListLayout
} from 'react-aria-components';
import { useMemo, useRef, createContext, useContext, useId } from 'react';
import type { RefObject } from 'react';
import * as s from 'superstruct';

import {
  useDispatchChangeEvent,
  useMultiList,
  useSingleList,
  useRemoteList,
  useOnFormReset,
  createLoader,
  type ComboBoxProps
} from './react-aria/hooks';
import {
  type Item,
  SingleComboBoxProps,
  MultiComboBoxProps,
  RemoteComboBoxProps
} from './react-aria/props';

export function ComboBox({
  children,
  label,
  labelId,
  ariaLabelledbyPrefix,
  description,
  className,
  inputRef,
  isLoading,
  isOpen,
  placeholder,
  ...props
}: ComboBoxProps & {
  inputRef?: RefObject<HTMLInputElement | null>;
  isOpen?: boolean;
  placeholder?: string;
}) {
  const generatedId = useId();
  // if label is passed, we need to generate an id for the input, otherwise we use the labelId passed in the props
  const idToUse = label ? generatedId : labelId;

  const inputAriaLabelledby = ariaLabelledbyPrefix
    ? `${ariaLabelledbyPrefix} ${idToUse}`
    : idToUse;

  return (
    <AriaComboBox
      {...props}
      className={`fr-ds-combobox ${className ?? ''}`}
      shouldFocusWrap={true}
    >
      {label ? (
        <Label className="fr-label" id={labelId}>
          {label}
          {description ? (
            <Text slot="description" className="fr-hint-text fr-mb-1w">
              {description}
            </Text>
          ) : null}
        </Label>
      ) : null}
      <div className="fr-ds-combobox__input" style={{ position: 'relative' }}>
        <Input
          className="fr-select fr-autocomplete"
          ref={inputRef}
          aria-busy={isLoading}
          aria-labelledby={inputAriaLabelledby}
          placeholder={placeholder || undefined}
          translate="no"
        />
        <Button
          aria-haspopup="false"
          aria-label=""
          style={{
            width: '40px',
            height: '100%',
            position: 'absolute',
            opacity: 0,
            right: 0,
            top: 0
          }}
        >
          {' '}
        </Button>
      </div>
      <Popover className="fr-ds-combobox__menu fr-menu" isOpen={isOpen}>
        <Virtualizer layout={ListLayout}>
          <ListBox className="fr-menu__list">{children}</ListBox>
        </Virtualizer>
      </Popover>
    </AriaComboBox>
  );
}

export function ComboBoxItem(props: ListBoxItemProps<Item>) {
  if (props.id == 'combo-alert-message') {
    return (
      <ListBoxItem
        {...props}
        isDisabled={true}
        className="fr-menu__item fr-badge fr-badge--info fr-badge--no-text-transform width-100"
      />
    );
  }
  return <ListBoxItem {...props} className="fr-menu__item" />;
}

export function SingleComboBox({
  children,
  ...maybeProps
}: SingleComboBoxProps) {
  const {
    items: defaultItems,
    selectedKey: defaultSelectedKey,
    placeholder,
    emptyFilterKey,
    name,
    formValue,
    form,
    data,
    ...props
  } = useMemo(() => s.create(maybeProps, SingleComboBoxProps), [maybeProps]);

  const { ref, dispatch } = useDispatchChangeEvent();

  const { selectedItem, onReset, ...comboBoxProps } = useSingleList({
    defaultItems,
    defaultSelectedKey,
    emptyFilterKey,
    onChange: dispatch
  });

  return (
    <>
      <ComboBox
        menuTrigger="focus"
        placeholder={placeholder}
        {...comboBoxProps}
        {...props}
      >
        {(item) => <ComboBoxItem id={item.value}>{item.label}</ComboBoxItem>}
      </ComboBox>
      {children || name ? (
        <span ref={ref}>
          <SelectedItemProvider value={selectedItem}>
            {name ? (
              <ComboBoxValueSlot
                field={formValue == 'text' ? 'label' : 'value'}
                name={name}
                form={form}
                onReset={onReset}
                data={data}
              />
            ) : null}
            {children}
          </SelectedItemProvider>
        </span>
      ) : null}
    </>
  );
}

export function MultiComboBox(maybeProps: MultiComboBoxProps) {
  const {
    items: defaultItems,
    selectedKeys: defaultSelectedKeys,
    placeholder,
    name,
    form,
    formValue,
    allowsCustomValue,
    valueSeparator,
    className,
    focusOnSelect,
    ...props
  } = useMemo(() => s.create(maybeProps, MultiComboBoxProps), [maybeProps]);

  const { ref, dispatch } = useDispatchChangeEvent();
  const inputRef = useRef<HTMLInputElement>(null);

  const {
    selectedItems,
    hiddenInputValues,
    onRemove,
    onReset,
    ...comboBoxProps
  } = useMultiList({
    defaultItems,
    defaultSelectedKeys,
    formValue,
    allowsCustomValue,
    valueSeparator,
    focusInput: () => {
      inputRef.current?.focus();
    },
    onChange: () => {
      dispatch();
      if (focusOnSelect) {
        document.getElementById(focusOnSelect)?.focus();
      }
    }
  });
  const formResetRef = useOnFormReset(onReset);

  return (
    <div className={`fr-ds-combobox__multiple ${className ? className : ''}`}>
      {selectedItems.length > 0 ? (
        <TagGroup onRemove={onRemove} aria-label={props['aria-label']}>
          <TagList items={selectedItems} className="fr-tag-list">
            {selectedItems.map((item) => (
              <Tag
                key={item.value}
                id={item.value}
                textValue={`Retirer ${item.label}`}
                className="fr-tag fr-tag--sm fr-tag--dismiss"
              >
                {item.label}
                <Button
                  aria-label=""
                  slot="remove"
                  className="fr-tag--dismiss"
                ></Button>
              </Tag>
            ))}
          </TagList>
        </TagGroup>
      ) : null}
      <ComboBox
        allowsCustomValue={allowsCustomValue}
        inputRef={inputRef}
        menuTrigger="focus"
        placeholder={placeholder}
        {...comboBoxProps}
        {...props}
      >
        {(item) => <ComboBoxItem id={item.value}>{item.label}</ComboBoxItem>}
      </ComboBox>
      {name ? (
        <span ref={ref}>
          {hiddenInputValues.length == 0 ? (
            <input
              type="hidden"
              value=""
              name={name}
              form={form}
              ref={formResetRef}
            />
          ) : (
            hiddenInputValues.map((value, i) => (
              <input
                type="hidden"
                value={value}
                name={name}
                form={form}
                ref={i == 0 ? formResetRef : undefined}
                key={value}
              />
            ))
          )}
        </span>
      ) : null}
    </div>
  );
}

export function RemoteComboBox({
  loader,
  onChange,
  children,
  ...maybeProps
}: RemoteComboBoxProps) {
  const {
    items: defaultItems,
    selectedKey: defaultSelectedKey,
    placeholder,
    minimumInputLength,
    limit,
    debounce,
    coerce,
    formValue,
    name,
    form,
    data,
    usePost,
    ...props
  } = useMemo(() => s.create(maybeProps, RemoteComboBoxProps), [maybeProps]);

  const { ref, dispatch } = useDispatchChangeEvent();

  const load = useMemo(
    () =>
      typeof loader === 'string'
        ? createLoader(loader, {
            minimumInputLength,
            limit,
            coerce,
            usePost
          })
        : loader,
    [loader, minimumInputLength, limit, coerce, usePost]
  );

  const { selectedItem, onReset, shouldShowPopover, ...comboBoxProps } =
    useRemoteList({
      defaultItems,
      defaultSelectedKey,
      debounce,
      load,
      onChange: (item) => {
        onChange?.(item);
        dispatch();
      }
    });

  return (
    <>
      <ComboBox
        placeholder={placeholder}
        allowsEmptyCollection={
          comboBoxProps.inputValue.length >= (minimumInputLength ?? 0)
        }
        isOpen={shouldShowPopover}
        {...comboBoxProps}
        {...props}
      >
        {(item) => <ComboBoxItem id={item.value}>{item.label}</ComboBoxItem>}
      </ComboBox>
      {children || name ? (
        <span ref={ref}>
          <SelectedItemProvider value={selectedItem}>
            {name ? (
              <ComboBoxValueSlot
                field={formValue == 'text' ? 'label' : 'value'}
                name={name}
                form={form}
                onReset={onReset}
                data={data}
              />
            ) : null}
            {children}
          </SelectedItemProvider>
        </span>
      ) : null}
    </>
  );
}

export function ComboBoxValueSlot({
  field,
  name,
  form,
  onReset,
  data
}: {
  field: 'label' | 'value' | 'data';
  name: string;
  form?: string;
  onReset?: () => void;
  data?: Record<string, string>;
}) {
  const selectedItem = useContext(SelectedItemContext);
  const value = getSelectedValue(selectedItem, field);
  const dataProps = Object.fromEntries(
    Object.entries(data ?? {}).map(([key, value]) => [
      `data-${key.replace(/_/g, '-')}`,
      value
    ])
  );
  const ref = useOnFormReset(onReset);
  return (
    <input
      ref={onReset ? ref : undefined}
      type="hidden"
      name={name}
      value={value}
      form={form}
      {...dataProps}
    />
  );
}

const SelectedItemContext = createContext<Item | null>(null);
const SelectedItemProvider = SelectedItemContext.Provider;

function getSelectedValue(
  selectedItem: Item | null,
  field: 'label' | 'value' | 'data'
): string {
  if (selectedItem == null) {
    return '';
  } else if (field == 'data') {
    if (typeof selectedItem.data == 'string') {
      return selectedItem.data;
    } else if (!selectedItem.data) {
      return '';
    }
    return JSON.stringify(selectedItem.data);
  }
  return selectedItem[field];
}
