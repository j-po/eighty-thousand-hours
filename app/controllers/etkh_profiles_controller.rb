class EtkhProfilesController < ApplicationController
  load_and_authorize_resource :only => [:new,:create,:edit,:update,:destroy]

  def new
    @etkh_profile = EtkhProfile.new
    current_user.etkh_profile = @etkh_profile
    @menu_root = "Membership"
    @menu_current = "Join now"
  end

  def join
    @menu_root = "Membership"
    @menu_current = "Join now"
  end

  def create
    if current_user.nil?
      raise CanCan::AccessDenied.new("You need to create an account first!", :create, EtkhProfile)
    end

    @etkh_profile = EtkhProfile.new(params[:etkh_profile])
    
    if @etkh_profile.save
      current_user.etkh_profile = @etkh_profile

      # fire off an email informing 80k team (join@80k..)
      EtkhProfileMailer.tell_team(current_user).deliver!

      # send an email to the user
      EtkhProfileMailer.thank_applicant(current_user).deliver!

      # add name to 'show your support'
      @supporter = Supporter.new(:name => current_user.name, :email => current_user.email)
      @supporter.save

      thanks_str = "Thank you for your interest in 80,000 Hours, " << current_user.first_name << ". \
        We've received your application and you'll hear from us soon!"
      flash[:"alert-success"] = thanks_str

      # redirects should be full url for browser compatibility
      redirect_to root_url
    else
      render :new
    end
  end

  def index
    get_grouped_profiles

    @menu_root = "Our community"
    @menu_current = "Our members"
  end

  def get_grouped_profiles
    @profiles = EtkhProfile.all.to_a.sort_by{|p| p.user.name[0].upcase }
    @grouped_profiles = @profiles.group_by{ |profile| profile.user.name[0].upcase }
    @newest_profiles = EtkhProfile.newest.limit(8)
  end

  def show
    @user = User.find(params[:id])
    @title = @user.name
    @donations = @user.donations.confirmed
    @profile = @user.etkh_profile

    @menu_root = "Our community"
    @menu_current = "Our members"
  end

  def destroy
    profile = EtkhProfiles.find( params[:id] )
    if profile.destroy
      flash[:"alert-success"] = "Deleted profile"
    else
      flash[:"alert-error"] = "Failed to delete profile!"
    end
    redirect_to users_path
  end

  def edit
    @etkh_profile = current_user.etkh_profile
  end

  def update
    if current_user.update_attributes(params[:user])
      flash[:"alert-success"] = "Your profile was successfully updated."
      redirect_to( etkh_profile_path( current_user ) )
    else
      render :action => "edit"
    end
  end

  def search
    @user = User.find_by_name(params[:name])
    if @user
      redirect_to etkh_profile_path(@user)
    else
      flash[:"alert-error"] = "Couldn't find #{params[:name]}!"
      redirect_to :action => :index
    end
  end

  def email_list
    @members = EtkhProfile.order("created_at ASC")

    authorize! :read, EtkhProfile
  end
end
