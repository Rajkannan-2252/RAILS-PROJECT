module Api
  class CloudNetworksController < ApplicationController
    skip_before_action :verify_authenticity_token
    
    def available_vms
      network = find_network(params[:id])
      return render_not_found unless network
      
      begin
        # Get VMs that are not already attached to this network
        provider = network.ext_management_system
        all_vms = provider.vms
        attached_vm_ids = network.vms.pluck(:id)
        available_vms = all_vms.reject { |vm| attached_vm_ids.include?(vm.id) }
        
        vm_list = available_vms.map { |vm| { id: vm.id.to_s, name: vm.name } }
        
        render json: { vms: vm_list }
      rescue => e
        Rails.logger.error("Error fetching available VMs: #{e}")
        render json: { error: e.message }, status: :internal_server_error
      end
    end
    
    def attached_vms
      network = find_network(params[:id])
      return render_not_found unless network
      
      begin
        vm_list = network.vms.map { |vm| { id: vm.id.to_s, name: vm.name } }
        render json: { vms: vm_list }
      rescue => e
        Rails.logger.error("Error fetching attached VMs: #{e}")
        render json: { error: e.message }, status: :internal_server_error
      end
    end
    
    def attach
      network = find_network(params[:id])
      return render_not_found unless network
      
      begin
        vm = VmCloud.find_by(id: params[:vm_id])
        return render json: { error: "VM not found" }, status: :not_found unless vm
        
        # Create a port and connect the VM to the network
        provider = network.ext_management_system
        connection_options = { service: "Network" }
        connection = provider.connect(connection_options)
        
        # Create port params
        port_params = {
          network_id: network.ems_ref,
          device_id: vm.ems_ref,
          device_owner: "compute:nova",
          tenant_id: network.cloud_tenant.ems_ref,
          name: "port-#{vm.name}-#{network.name}"
        }
        
        # Create the port
        port = connection.create_port(port_params)
        
        # Queue a refresh to update inventory
        EmsRefresh.queue_refresh(network)
        EmsRefresh.queue_refresh(vm)
        
        render json: { 
          success: true, 
          message: "Attaching network '#{network.name}' to VM '#{vm.name}'",
          port_id: port.body['port']['id']
        }
      rescue => e
        Rails.logger.error("Error attaching network: #{e}")
        render json: { error: e.message }, status: :internal_server_error
      end
    end
    
    def detach
      network = find_network(params[:id])
      return render_not_found unless network
      
      begin
        vm = VmCloud.find_by(id: params[:vm_id])
        return render json: { error: "VM not found" }, status: :not_found unless vm
        
        # Find the port connecting the VM to the network
        provider = network.ext_management_system
        connection_options = { service: "Network" }
        connection = provider.connect(connection_options)
        
        # Find the port
        ports = connection.ports.select do |p| 
          p.device_id == vm.ems_ref && p.network_id == network.ems_ref
        end
        
        if ports.empty?
          return render json: { 
            error: "No connection found between network '#{network.name}' and VM '#{vm.name}'"
          }, status: :not_found
        end
        
        # Delete the port(s)
        ports.each do |port|
          connection.delete_port(port.id)
        end
        
        # Queue a refresh to update inventory
        EmsRefresh.queue_refresh(network)
        EmsRefresh.queue_refresh(vm)
        
        render json: { 
          success: true, 
          message: "Detaching network '#{network.name}' from VM '#{vm.name}'"
        }
      rescue => e
        Rails.logger.error("Error detaching network: #{e}")
        render json: { error: e.message }, status: :internal_server_error
      end
    end
    
    private
    
    def find_network(id)
      CloudNetwork.find_by(id: id)
    end
    
    def render_not_found
      render json: { error: "Cloud network not found" }, status: :not_found
    end
  end
end