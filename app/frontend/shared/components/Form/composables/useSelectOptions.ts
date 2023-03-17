// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type Ref, watch } from 'vue'
import { i18n } from '@shared/i18n'
import { cloneDeep, keyBy } from 'lodash-es'
import type {
  SelectOptionSorting,
  SelectOption,
  SelectValue,
} from '../fields/FieldSelect'
import type { FormFieldContext } from '../types/field'
import type { FlatSelectOption } from '../fields/FieldTreeSelect'
import type { AutoCompleteOption } from '../fields/FieldAutoComplete'
import useValue from './useValue'

const useSelectOptions = <
  T extends SelectOption[] | FlatSelectOption[] | AutoCompleteOption[],
>(
  options: Ref<T>,
  context: Ref<
    FormFieldContext<{
      historicalOptions?: Record<string, string>
      multiple?: boolean
      noOptionsLabelTranslation?: boolean
      rejectNonExistentValues?: boolean
      sorting?: SelectOptionSorting
    }>
  >,
) => {
  const dialog = ref<HTMLElement>()

  const { currentValue, hasValue, valueContainer, clearValue } =
    useValue(context)

  const appendedOptions = ref<T>([] as unknown as T) as Ref<T>

  const availableOptions = computed(() => [
    ...(options.value || []),
    ...appendedOptions.value,
  ])

  const hasStatusProperty = computed(() =>
    availableOptions.value?.some(
      (option) => (option as SelectOption | FlatSelectOption).status,
    ),
  )

  const translatedOptions = computed(() => {
    if (!availableOptions.value) return []

    const { noOptionsLabelTranslation } = context.value

    return availableOptions.value.map((option) => {
      const label = noOptionsLabelTranslation
        ? option.label
        : i18n.t(option.label, ...(option.labelPlaceholder || []))

      const variant = option as AutoCompleteOption
      const heading = noOptionsLabelTranslation
        ? variant.heading
        : i18n.t(variant.heading, ...(variant.headingPlaceholder || []))

      return {
        ...option,
        label,
        heading,
      } as SelectOption | AutoCompleteOption
    })
  })

  const optionValueLookup = computed(() =>
    keyBy(translatedOptions.value, 'value'),
  )

  const sortedOptions = computed(() => {
    const { sorting } = context.value

    if (!sorting) return translatedOptions.value

    if (sorting !== 'label' && sorting !== 'value') {
      console.warn(`Unsupported sorting option "${sorting}"`)
      return translatedOptions.value
    }

    return [...translatedOptions.value]?.sort((a, b) => {
      const aLabelOrValue = a[sorting] || a.value
      const bLabelOrValue = b[sorting] || a.value
      return String(aLabelOrValue).localeCompare(String(bLabelOrValue))
    })
  })

  const getSelectedOption = (selectedValue: SelectValue) => {
    const key = selectedValue.toString()
    return optionValueLookup.value[key]
  }

  const getSelectedOptionIcon = (selectedValue: SelectValue) => {
    const option = getSelectedOption(selectedValue)
    return option?.icon as string
  }

  const getSelectedOptionLabel = (selectedValue: SelectValue) => {
    const option = getSelectedOption(selectedValue)
    return option?.label
  }

  const getSelectedOptionStatus = (selectedValue: SelectValue) => {
    const option = getSelectedOption(selectedValue) as
      | SelectOption
      | FlatSelectOption
    return option?.status
  }

  const selectOption = (option: T extends Array<infer V> ? V : never) => {
    if (!context.value.multiple) {
      context.value.node.input(option.value)
      return
    }

    const selectedValues = cloneDeep(currentValue.value) || []
    const optionIndex = selectedValues.indexOf(option.value)
    if (optionIndex !== -1) selectedValues.splice(optionIndex, 1)
    else selectedValues.push(option.value)
    selectedValues.sort(
      (a: string | number, b: string | number) =>
        sortedOptions.value.findIndex((option) => option.value === a) -
        sortedOptions.value.findIndex((option) => option.value === b),
    )
    context.value.node.input(selectedValues)
  }

  const getDialogFocusTargets = (optionsOnly?: boolean): HTMLElement[] => {
    const containerElement = dialog.value?.parentElement
    if (!containerElement) return []

    const targetElements = Array.from(
      containerElement.querySelectorAll<HTMLElement>('[tabindex="0"]'),
    )
    if (!targetElements) return []

    if (optionsOnly)
      return targetElements.filter(
        (targetElement) =>
          targetElement.attributes.getNamedItem('role')?.value === 'option',
      )

    return targetElements
  }

  const handleValuesForNonExistingOptions = () => {
    if (!hasValue.value || context.value.pendingValueUpdate) return

    if (context.value.multiple) {
      const availableValues = currentValue.value.filter(
        (selectValue: string | number) =>
          typeof optionValueLookup.value[selectValue] !== 'undefined',
      ) as SelectValue[]

      if (availableValues.length !== currentValue.value.length) {
        context.value.node.input(availableValues, false)
      }

      return
    }

    if (typeof optionValueLookup.value[currentValue.value] === 'undefined')
      clearValue(false)
  }

  // Setup a mechanism to handle missing options, including:
  //   - appending historical options for current values
  //   - clearing value in case options are missing
  const setupMissingOptionHandling = () => {
    const { historicalOptions } = context.value

    // When we are in a "create" form situation and no 'rejectNonExistentValues' flag
    // is given, it should be activated.
    if (context.value.rejectNonExistentValues === undefined) {
      const rootNode = context.value.node.at('$root')
      context.value.rejectNonExistentValues =
        rootNode &&
        rootNode.name !== context.value.node.name &&
        !rootNode.context?.initialEntityObject
    }

    // Remember current optionValueLookup in node context.
    context.value.optionValueLookup = optionValueLookup

    // TODO: Workaround, because currently the "nulloption" exists also for multiselect fields (#4513).
    if (context.value.multiple) {
      watch(
        () =>
          hasValue.value &&
          valueContainer.value.includes('') &&
          context.value.clearable &&
          !options.value.some((option) => option.value === ''),
        () => {
          const emptyOption: SelectOption = {
            value: '',
            label: '-',
          }

          ;(appendedOptions.value as SelectOption[]).unshift(emptyOption)
        },
      )
    }

    // Append historical options to the list of available options, if:
    //   - non-existent values are not supposed to be rejected
    //   - we have a current value
    //   - we have a list of historical options
    if (
      !context.value.rejectNonExistentValues &&
      hasValue.value &&
      historicalOptions
    ) {
      appendedOptions.value = valueContainer.value.reduce(
        (accumulator: SelectOption[], value: SelectValue) => {
          const label = historicalOptions[value.toString()]
          // Make sure the options are not duplicated!
          if (
            label &&
            !options.value.some((option) => option.value === value)
          ) {
            accumulator.push({ value, label })
          }
          // TODO: Workaround, because currently the "nulloption" exists also for multiselect fields (#4513).
          else if (
            context.value.multiple &&
            !label &&
            value === '' &&
            !options.value.some((option) => option.value === value)
          ) {
            accumulator.unshift({ value, label: '-' })
          }

          return accumulator
        },
        [],
      )
    }

    // Reject non-existent values during the initialization phase.
    //   Note that this behavior is controlled by a dedicated flag.
    if (context.value.rejectNonExistentValues)
      handleValuesForNonExistingOptions()

    // Set up a watcher that clears a missing option value on subsequent mutations of the options prop.
    //   In this case, the dedicated flag is ignored.
    watch(() => options.value, handleValuesForNonExistingOptions)
  }

  return {
    dialog,
    hasStatusProperty,
    translatedOptions,
    optionValueLookup,
    sortedOptions,
    getSelectedOption,
    getSelectedOptionIcon,
    getSelectedOptionLabel,
    getSelectedOptionStatus,
    selectOption,
    getDialogFocusTargets,
    setupMissingOptionHandling,
    appendedOptions,
  }
}

export default useSelectOptions
