class CommentsController < ApplicationController
  
  no_login_required
  skip_before_filter :verify_authenticity_token
  before_filter :find_product
  before_filter :set_host

  def index
    @product.selected_comment = @product.comments.find_by_id(flash[:selected_comment])
    render :text => @product.render
  end
  
  def create
    comment = Comment.new
    comment.content = "#{params[:comment][:content]}".strip
    @auth = "#{params[:comment][:author]}".strip
    if @auth.empty?
      comment.author = 'not specified'
    else
      comment.author = @auth 
    end
    @auth_email = "#{params[:comment][:author_email]}".strip
    
    if @auth_email.empty?
      comment.author_email = 'not specified'
    else
      comment.author_email = @auth_email
    end

    comment.save!
    @product.comments << comment
    puts comment.errors.full_messages.inspect
    
    ResponseCache.instance.clear
    CommentMailer.deliver_comment_notification(comment) if Radiant::Config['comments.notification'] == "true"
    
    flash[:selected_comment] = comment.id
    redirect_to "/products/#{@product.slug}#comment-#{comment.id}"
  rescue ActiveRecord::RecordInvalid
    @product.last_comment = comment
    puts comment.errors.full_messages.inspect
    redirect_to "/products/#{@product.slug}#comment-#{comment.id}"
  end
  
  private
  
    def find_product
      # was find_by_url, changed to find_by_slug
      @product = Product.find_by_id(params['product_id'])
    end
    
    def set_host
      CommentMailer.default_url_options[:host] = request.host_with_port
    end
  
end
