import React from 'react';
import ReactDOM from 'react-dom';
import AttachDetachCloudNetworkForm from '../components/attach-detach-cloud-network-form';
import '../components/attach-detach-cloud-network-form.scss';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('react-attach-detach-cloud-network-form');
  
  if (container) {
    const {
      recordId,
      isAttach,
      dropdownChoices,
      dropdownLabel,
    } = container.dataset;
    
    // Parse JSON data from attributes
    const parsedChoices = JSON.parse(dropdownChoices || '[]');
    const parsedIsAttach = isAttach === 'true';
    
    ReactDOM.render(
      <AttachDetachCloudNetworkForm
        recordId={recordId}
        isAttach={parsedIsAttach}
        dropdownChoices={parsedChoices}
        dropdownLabel={dropdownLabel || 'Instance'}
      />,
      container
    );
  }
});