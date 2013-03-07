class EtkhProfilesController < ApplicationController
  load_and_authorize_resource :only => [:new,:create,:edit,:update,:destroy]

  def new     #this is not triggered when a new member signs up
    if current_user.nil?
      raise CanCan::AccessDenied.new("You need to create an account first!", :create, EtkhProfile)
    end

    if current_user.etkh_profile.nil?
      # create a new profile for the user
      @etkh_profile = EtkhProfile.new
      current_user.etkh_profile = @etkh_profile

      # fire off an email informing 80k team (join@80k..)
      EtkhProfileMailer.tell_team(current_user).deliver!

      # send an email to the user
      EtkhProfileMailer.thank_applicant(current_user).deliver!

      # add name to 'show your support'
      @supporter = Supporter.new(:name => current_user.name, :email => current_user.email)
      @supporter.save

      redirect_to members_survey_path
    else
      # user already has a profile but has visited /members/new
      render 'edit'
    end
    @menu_root = "Membership"
    @menu_current = "Join now"
  end

  def index
    get_grouped_profiles

    @title = "Members"
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

    if !@profile.public_profile && !current_user
      @error_type = "signup"
      @error_message = "This member's profile is private."
      if request.xhr?
        render 'shared/sign_up_modal'
      else
        render 'shared/display_error'
      end
    end

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

    # indicate whether profile is being created for first time or not
    @new_profile = session[:new_profile] == "true" ? true : false
    session[:new_profile] = nil

    # indicate whether user has signedup with linkedin or not
    @linkedin_signup = current_user.linkedin_email ? true : false

    if @new_profile == true 
      flash[:"alert-success"] = "Account successfully created."
    end
  end

  def update
    if params[:user][:external_website][0..6] != "http://"
      params[:user][:external_website] = "http://" + params[:user][:external_website]
    end

    if current_user.update_attributes(params[:user])
      flash[:"alert-success"] = "Your profile was successfully updated."
      
      #work out time since user profile was first created
      timediff = Time.now - current_user.confirmed_at   #in seconds
      timediff = timediff / 60  #in minutes

      #if much time has elapsed since the profile was created
      maxTime = 60 #minutes
      if timediff > maxTime
        #assume the user is editing their profile
        redirect_to( etkh_profile_path( current_user ) )
      else
        #assume the user is creating their profile for the first time
        redirect_to( members_survey_path )
      end
    else
      render :action => "edit"
    end
  end

  def search
    # perform searching in model
    results = User.search(params[:search])

    # store results in session data as user ids
    session[:search_results] = []
    results.each do |user|
      session[:search_results] << user.id
    end

    # display first entries
    list_length = 10
    selection = results.first(list_length)
    render partial: 'profiles_selection', locals: { users: selection }

    # create pointer to indicate which results are already displayed
    session[:search_results][:pointer] = list_length
  end

  def our_members
    # displays list of members within community page

    # set up navbar
    @menu_root = "Our community"
    @menu_current = "Our members"
    @title = "Members"

    ## get list of users to be displayed
    list_length = 10

    # get already selected users from session data
    # note this means that if the user leaves the page and returns to it
    # the previously selected users will still be selected
    if session[:selected_users]
      @selected_users = []
      session[:selected_users].each do |user_id|
        @selected_users << User.find_by_id(user_id)
      end
    end

    # generate users using algorithm
    if @selected_users
      # remove currently selected users from searching set
      @next_selection = EtkhProfile.generate_users(list_length, @selected_users)
      @selected_users.concat(@next_selection)
    else
      @next_selection = EtkhProfile.generate_users(list_length)
      @selected_users = @next_selection
    end

    # store newly selected users in session variable
    session[:selected_users] = [] if !session[:selected_users]
    @next_selection.each do |user|
      session[:selected_users] << user.id
    end

    # if an AJAX request render newly selected users only
    if request.xhr?
      render partial: 'profiles_selection', locals: { users: @next_selection }
    end
  end
end
