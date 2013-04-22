class BlogPostsController < ApplicationController
  load_and_authorize_resource :only => [:new,:create,:drafts,:edit,:update,:destroy]
  caches_action :index, cache_path: Proc.new { |controller| controller.params }, expires_in: 4.hours

  def index
    @posts = BlogPost.published.paginate(:page => params[:page], :per_page => 10)
    @condensed = false
    @heading = "80,000 Hours blog"

    @title = "Blog"
    @menu_root = "Blog"
  end

  def drafts
    @posts = BlogPost.by_author_drafts(current_user)
    @title = "Blog"
    @menu_root = "Blog"
  end

  def sorted
    @sort = params[:order]
    case @sort
    when 'popularity'
      @posts = BlogPost.by_popularity
      @condensed = true
      @heading = "Most popular posts"
    when 'votes'
      @posts = BlogPost.by_votes
      @condensed = true
      @heading = "Highest voted posts"
    when 'date'
      @posts = BlogPost.published
      @condensed = true
      @heading = "All posts by date"
    else
      @posts = BlogPost.published.paginate(:page => params[:page], :per_page => 10)
      @condensed = false
      @heading = "80,000 Hours blog"
    end

    @title = "Blog"
    @menu_root = "Blog"
  end

  def show
    @post = BlogPost.find_by_id(params[:id])
    if @post.nil?
      flash[:"alert-error"] = "Sorry! You've followed a bad link, please <a href='contact-us'>contact support</a> and report the following:<br/> #{params[:controller]} => '#{params[:id]}'".html_safe
      redirect_to :action => 'index'
    else
      if @post.draft
        if cannot? :manage, BlogPost
          # user is not allowed to view drafts
          # so we redirect to the index
          flash[:"alert-error"] = "Sorry! You've followed a bad link, please <a href='contact-us'>contact support</a>!".html_safe
          redirect_to :action => 'index'
        end
      end

      @og_url = blog_post_url( @post )
      @og_desc = @post.get_teaser
      @og_type = "article"
      @title = "Blog: " + @post.title
      @tags = @post.tag_list

      @menu_root = "Blog"
    end
  end

  def author
    @heading = "BlogPosts by #{params[:id]}"
    @posts = BlogPost.by_author(params[:id],params[:page])
    @condensed = true

    render :action => 'index'
  end

  def vote
    post = BlogPost.find( params[:id] )
    user = current_user
    
    if !user
      flash[:"alert-warn"] = "You need to sign in or sign up to vote!"
    else
      post.vote!( user, (params[:up] == 'true') ? true : false )
    end
    expire_action :action => :index
    redirect_to :action => 'index' 
  end

  def tag
    @heading = "BlogPosts tagged with '#{params[:id]}'"
    @posts = BlogPost.published.tagged_with(params[:id]).order("created_at DESC").paginate(:page => params[:page], :per_page => 10)
    @condensed = true

    render 'index'
  end

  # Atom feed
  def feed
    # this will be the name of the feed displayed on the feed reader
    @title = "80,000 Hours - Blog"

    # the blog posts
    @posts = BlogPost.published

    # this will be our feed's update timestamp
    @updated = @posts.first.updated_at unless @posts.empty?

    respond_to do |format|
      format.atom { render :layout => false } #views/posts/feed.atom.builder
    end
  end

  def edit
    @post = BlogPost.find( params[:id] )
    3.times { @post.attached_images.build }
  end

  def update
    @post = BlogPost.find( params[:id] )
    if @post.update_attributes( params[:blog_post] )
      redirect_to @post, :notice => "Post updated!"
    else
      render :edit
    end
    expire_action :action => :index
  end

  def new
    @post = BlogPost.new
    3.times { @post.attached_images.build }
  end

  def create
    @post = current_user.blog_posts.new( params[:blog_post] )
    if @post.save
      redirect_to blog_post_path(@post), :notice => "Post created!"
    else
      render :new
    end
    expire_action :action => :index
  end

  def destroy
    @post = BlogPost.find( params[:id] )
    @post.destroy
    redirect_to blog_posts_path, :notice => "Post permanently deleted"
    expire_action :action => :index
  end

  private
  def can_vote_on_post? (user, post )
    !user.nil?
  end
end
