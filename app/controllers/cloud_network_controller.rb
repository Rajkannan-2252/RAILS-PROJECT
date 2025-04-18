class CloudNetworkController < ApplicationController
  before_action :check_privileges
  
  def show
    @network = find_record_with_rbac(CloudNetwork, params[:id])
    drop_breadcrumb(:name => @network.name, :url => "/cloud_network/show/#{@network.id}")
  end

  def detach
    params[:id] = checked_item_id if params[:id].blank?
    assert_privileges("cloud_network_detach")
    Rails.logger.info("Starting detach process for cloud network")
    Rails.logger.info("Params received: #{params.to_unsafe_h.inspect}")
    
    @network = find_record_with_rbac(CloudNetwork, params[:id])
    Rails.logger.info("Found network: #{@network.name} (ID: #{@network.id})")
    
    # Get all VMs attached to this network
    @vm_choices = {}
    @network.vms.each { |vm| @vm_choices[vm.name] = vm.id }
    Rails.logger.info("Available VMs for detachment: #{@vm_choices.keys.join(', ')}")
    
    @in_a_form = true
    drop_breadcrumb(
      :name => _("Detach Cloud Network \"%{name}\"") % {:name => @network.name},
      :url  => "/cloud_network/detach/#{@network.id}"
    )
    Rails.logger.info("Breadcrumb set for Detach Cloud Network: #{@network.name}")
  end
  
  def attach
    params[:id] = checked_item_id if params[:id].blank?
    assert_privileges("cloud_network_attach")
    Rails.logger.info("Starting attach process for cloud network")
    Rails.logger.info("Params received: #{params.to_unsafe_h.inspect}")
    
    @network = find_record_with_rbac(CloudNetwork, params[:id])
    Rails.logger.info("Found network: #{@network.name} (ID: #{@network.id})")
    
    # Get all VMs that could be attached to this network (not already attached)
    provider = @network.ext_management_system
    @vm_choices = {}
    
    if provider
      all_vms = provider.vms
      attached_vm_ids = @network.vms.pluck(:id)
      available_vms = all_vms.reject { |vm| attached_vm_ids.include?(vm.id) }
      available_vms.each { |vm| @vm_choices[vm.name] = vm.id }
    end
    
    Rails.logger.info("Available VMs for attachment: #{@vm_choices.keys.join(', ')}")
    
    @in_a_form = true
    drop_breadcrumb(
      :name => _("Attach Cloud Network \"%{name}\"") % {:name => @network.name},
      :url  => "/cloud_network/attach/#{@network.id}"
    )
    Rails.logger.info("Breadcrumb set for Attach Cloud Network: #{@network.name}")
  end

  def detach_submit
    assert_privileges("cloud_network_detach")
    Rails.logger.info("Processing detachment for cloud network")
    
    @network = find_record_with_rbac(CloudNetwork, params[:id])
    vm_id = params[:vm_id] || params.dig(:resource, :vm_id)
    
    if vm_id.blank?
      add_flash(_("No VM selected for detachment"), :error)
      javascript_redirect previous_breadcrumb_url
      return
    end
    
    vm = find_record_with_rbac(VmCloud, vm_id)
    Rails.logger.info("Detaching network #{@network.name} from VM #{vm.name}")
    
    begin
      # Get the OpenStack connection
      ext_management_system = @network.ext_management_system
      connection_options = {:service => "Network"}
      connection = ext_management_system.connect(connection_options)
      
      # Find and detach the port connecting the VM to the network
      port = connection.ports.find { |p| p.device_id == vm.ems_ref && p.network_id == @network.ems_ref }
      
      if port
        Rails.logger.info("Found port to detach: #{port.id}")
        connection.delete_port(port.id)
        add_flash(_("Cloud Network \"%{name}\" is being detached from \"%{vm_name}\"") % {
          :name => @network.name, :vm_name => vm.name
        })
        
        # Queue a refresh of the network and VM
        EmsRefresh.queue_refresh(@network)
        EmsRefresh.queue_refresh(vm)
      else
        add_flash(_("No connection found between Cloud Network \"%{name}\" and VM \"%{vm_name}\"") % {
          :name => @network.name, :vm_name => vm.name
        }, :error)
      end
    rescue => e
      add_flash(_("Unable to detach Cloud Network \"%{name}\" from VM \"%{vm_name}\": %{error}") % {
        :name => @network.name, :vm_name => vm.name, :error => e
      }, :error)
      Rails.logger.error("Error detaching network: #{e}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
    
    session[:flash_msgs] = @flash_array.dup
    javascript_redirect previous_breadcrumb_url
  end
  
  # API method for attach/detach
  def action
    result = {}
    if params[:action] == "detach" && params[:resources]
      detach_cloud_network(params[:resources])
      result = {
        :success => true,
        :message => _("Detaching Cloud Network"),
        :task_id => "detach_cloud_network_#{@network.id}"
      }
    elsif params[:action] == "attach" && params[:resources]
      attach_cloud_network(params[:resources])
      result = {
        :success => true,
        :message => _("Attaching Cloud Network"),
        :task_id => "attach_cloud_network_#{@network.id}"
      }
    end
    
    render :json => result
  end
  
  private
  
  def attach_cloud_network(resources)
    @network = find_record_with_rbac(CloudNetwork, params[:id])
    vm_id = resources[:vm_id]
    
    if vm_id.blank?
      render_bad_request_error("Must specify a VM when attaching a network")
      return
    end
    
    vm = find_record_with_rbac(VmCloud, vm_id)
    Rails.logger.info("Attaching network #{@network.name} to VM #{vm.name}")
    
    begin
      # Create a port and connect the VM to the network
      provider = @network.ext_management_system
      connection_options = { service: "Network" }
      connection = provider.connect(connection_options)
      
      # Create port params
      port_params = {
        network_id: @network.ems_ref,
        device_id: vm.ems_ref,
        device_owner: "compute:nova",
        tenant_id: @network.cloud_tenant.ems_ref,
        name: "port-#{vm.name}-#{@network.name}"
      }
      
      # Create the port
      port = connection.create_port(port_params)
      
      # Queue a refresh to update inventory
      EmsRefresh.queue_refresh(@network)
      EmsRefresh.queue_refresh(vm)
    rescue => e
      Rails.logger.error("Error attaching network: #{e}")
      render_error_message(e.message)
    end
  end
  
  def detach_cloud_network(resources)
    @network = find_record_with_rbac(CloudNetwork, params[:id])
    vm_id = resources[:vm_id]
    
    if vm_id.blank?
      render_bad_request_error("Must specify a VM when detaching a network")
      return
    end
    
    vm = find_record_with_rbac(VmCloud, vm_id)
    Rails.logger.info("Detaching network #{@network.name} from VM #{vm.name}")
    
    begin
      # Get the OpenStack connection
      provider = @network.ext_management_system
      connection_options = { service: "Network" }
      connection = provider.connect(connection_options)
      
      # Find the port connecting the VM to the network
      ports = connection.ports.select { |p| 
        p.device_id == vm.ems_ref && p.network_id == @network.ems_ref
      }
      
      if ports.empty?
        render_error_message("No connection found between network '#{@network.name}' and VM '#{vm.name}'")
        return
      end
      
      # Delete the port(s)
      ports.each do |port|
        connection.delete_port(port.id)
      end
      
      # Queue a refresh to update inventory
      EmsRefresh.queue_refresh(@network)
      EmsRefresh.queue_refresh(vm)
    rescue => e
      Rails.logger.error("Error detaching network: #{e}")
      render_error_message(e.message)
    end
  end
  
  def render_bad_request_error(message)
    render :json => { :error => message }, :status => :bad_request
  end
  
  def render_error_message(message)
    render :json => { :error => message }, :status => :internal_server_error
  end

  private

  def find_record_with_rbac(model, id)
    record = model.find_by(:id => id)
    if record.nil?
      flash_to_session(_("Error: Record no longer exists in the database"), :error)
      javascript_redirect(previous_breadcrumb_url)
      return nil
    end
    record
  end
  
  def checked_item_id
    params[:miq_grid_checks] || params[:id]
  end
end