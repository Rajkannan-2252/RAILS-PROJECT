import React from 'react';
import ReactDOM from 'react-dom';
import AttachDetachCloudNetworkForm from '../components/attach-detach-cloud-network-form';
import '../components/attach-detach-cloud-network-form.css';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('cloud-network-form-container');
  
  if (container) {
    const { networkId, networkName, formMode } = container.dataset;
    
    ReactDOM.render(
      <AttachDetachCloudNetworkForm 
        networkId={networkId}
        networkName={networkName}
        mode={formMode || 'detach'}
        onSuccess={() => {
          // Redirect back to network details page
          window.location.href = `/cloud_network/show/${networkId}`;
        }}
        onCancel={() => {
          // Go back to previous page
          window.history.back();
        }}
      />,
      container
    );
  }
});