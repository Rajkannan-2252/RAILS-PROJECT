class UserController < ApplicationController
  def index
    #render plain: "Welcome to the Users Index!"
    @user = User.all
  end

  def show
    @user = User.find(params[:id])
  end

end

def ownership
  assert_privileges('container_project_ownership')

  rec_ids = params[:rec_ids] || []
  if rec_ids.empty?
    add_flash(_("No records selected for ownership."), :error)
    return render_flash
  end

  @ownershipitems = find_records_with_rbac(ContainerProject, rec_ids)
  if @ownershipitems.empty?
    add_flash(_("Cannot access selected records."), :error)
    return render_flash
  end

  # Fetch users for ownership
  @users = User.order(:name) rescue []
  if @users.blank?
    add_flash(_("No users available for ownership."), :error)
    return render_flash
  end

  render :action => 'ownership'
end

