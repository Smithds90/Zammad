// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'
import FieldToggleInput from './FieldToggleInput.vue'

declare module '@formkit/inputs' {
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    toggle: {
      type: 'toggle'
      value?: boolean
      variants?: {
        true?: string
        false?: string
      }
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    toggle: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(FieldToggleInput, ['variants'], {
  features: [addLink, formUpdaterTrigger()],
})

export default {
  fieldType: 'toggle',
  definition: fieldDefinition,
}
