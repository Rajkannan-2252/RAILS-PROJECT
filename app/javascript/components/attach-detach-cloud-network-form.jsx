import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import MiqFormRenderer, { useFormApi } from '@@ddf';
import { FormSpy } from '@data-driven-forms/react-form-renderer';
import { Button } from 'carbon-components-react';
import miqRedirectBack from '../../helpers/miq-redirect-back';
import createSchema from './attach-detach-cloud-network.schema';

const AttachDetachCloudNetworkForm = ({ recordId, isAttach, dropdownChoices, dropdownLabel }) => {
  const [{ isLoading, fields }, setState] = useState({ isLoading: true, fields: [] });
  
  const loadSchema = (appendState = {}) => ({ data: { form_schema: { fields } } }) => {
    setState((state) => ({
      ...state,
      ...appendState,
      fields,
      isLoading: false,
    }));
  };

  const dropdownOptions = [];
  dropdownChoices.forEach((opt) => {
    dropdownOptions.push({ label: opt[0], value: opt[1].toString() });
  });

  useEffect(() => {
    if (isLoading && isAttach && dropdownLabel === "Instance") {
      API.options(`/api/cloud_networks/${recordId}?option_action=attach`)
        .then(loadSchema());
    } else if (isLoading) {
      setState((state) => ({
        ...state,
        isLoading: false,
      }));
    }
  }, [isLoading, isAttach, dropdownLabel, recordId]);

  const onSubmit = (values) => {
    miqSparkleOn();

    let vm_id, network_id, redirectUrl;
    if (dropdownLabel === "Instance") {
      network_id = recordId;
      vm_id = values.dropdown_id;
      redirectUrl = '/cloud_network/show_list';
    } else {
      network_id = values.dropdown_id;
      vm_id = recordId;
      redirectUrl = '/vm_cloud/explorer';
    }

    const resource = {
      vm_id: vm_id,
    };
    
    const payload = {
      action: isAttach ? 'attach' : 'detach',
      resource,
    };
    
    const request = API.post(`/api/cloud_networks/${network_id}`, payload);

    request.then(() => {
      const message = sprintf(isAttach
        ? __('Attachment of Cloud Network has been successfully queued.')
        : __('Detachment of Cloud Network has been successfully queued.'));

      miqRedirectBack(message, 'success', redirectUrl);
    }).catch(miqSparkleOff);
  };

  const onCancel = () => {
    miqSparkleOn();
    const message = sprintf(isAttach
      ? __('Attachment of Cloud Network was cancelled by the user.')
      : __('Detachment of Cloud Network was cancelled by the user.'));
    
    const redirectUrl = dropdownLabel === "Instance" 
      ? '/cloud_network/show_list' 
      : '/vm_cloud/explorer';
      
    miqRedirectBack(message, 'warning', redirectUrl);
  };

  if (isLoading) {
    return <div className="spinner spinner-lg"></div>;
  }

  const schema = createSchema(isAttach, dropdownLabel, dropdownOptions, fields);

  return (
    <MiqFormRenderer
      schema={schema}
      onSubmit={onSubmit}
      onCancel={onCancel}
      className="attach-detach-cloud-network-form"
      initialValues={{}}
      FormTemplate={props => (
        <FormTemplate
          {...props}
          isAttach={isAttach}
          fields={fields}
        />
      )}
    />
  );
};

const verifyIsDisabled = (values, fields) => {
  let isDisabled = true;
  if (values.dropdown_id && (!fields[0] || !fields[0].isRequired)) {
    isDisabled = false;
  }
  return isDisabled;
};

const FormTemplate = ({
  isAttach, fields, formFields,
}) => {
  const {
    handleSubmit, onReset, onCancel, getState,
  } = useFormApi();
  
  const { valid, pristine } = getState();
  const submitLabel = isAttach ? __('Attach') : __('Detach');
  
  return (
    <form onSubmit={handleSubmit}>
      {formFields}
      <FormSpy>
        {({ values }) => (
          <div className="custom-button-wrapper">
            <Button
              disabled={verifyIsDisabled(values, fields)}
              kind="primary"
              className="btnRight"
              type="submit"
              id="submit"
              variant="contained"
            >
              {submitLabel}
            </Button>
            <Button
              kind="secondary"
              className="btnRight"
              onClick={onCancel}
              id="cancel"
              variant="contained"
            >
              {__('Cancel')}
            </Button>
          </div>
        )}
      </FormSpy>
    </form>
  );
};

AttachDetachCloudNetworkForm.propTypes = {
  recordId: PropTypes.string.isRequired,
  isAttach: PropTypes.bool,
  dropdownChoices: PropTypes.array,
  dropdownLabel: PropTypes.string,
};

AttachDetachCloudNetworkForm.defaultProps = {
  isAttach: false,
  dropdownChoices: [],
  dropdownLabel: "Instance",
};

export default AttachDetachCloudNetworkForm;