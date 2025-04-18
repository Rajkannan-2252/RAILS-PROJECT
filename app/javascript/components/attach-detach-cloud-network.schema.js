import { __ } from '../i18n';

const createSchema = (isAttach, dropdownLabel, dropdownOptions, fields = []) => {
  // Include any custom fields that may have been returned from the API
  const customFields = fields.map((field) => ({
    ...field,
    title: __(field.title),
  }));

  const action = isAttach ? __('Attach') : __('Detach');
  const headerTitle = isAttach
    ? __('Attach Cloud Network')
    : __('Detach Cloud Network');
    
  const dropdownLabelText = dropdownLabel === 'Instance'
    ? isAttach ? __('Select Instance to attach network to') : __('Select Instance to detach network from')
    : isAttach ? __('Select Network to attach to instance') : __('Select Network to detach from instance');

  return {
    fields: [
      {
        component: 'sub-form',
        title: headerTitle,
        id: 'network-form',
        name: 'network-form',
        fields: [
          {
            component: 'select',
            name: 'dropdown_id',
            id: 'dropdown_id',
            label: dropdownLabelText,
            isRequired: true,
            validate: [{ type: 'required' }],
            options: dropdownOptions,
          },
          ...customFields,
          ...(isAttach ? [] : [
            {
              component: 'plain-text',
              name: 'warning',
              label: __('Warning: Detaching a network may disrupt connectivity. Make sure you understand the implications before proceeding.'),
              variant: 'warning',
            },
          ]),
        ],
      },
    ],
  };
};

export default createSchema;