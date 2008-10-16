class Admin::CommentsController < ApplicationController
  
  def index
    conditions = case params[:status]
    when "approved"
      "comments.approved_at IS NOT NULL"
    when "unapproved"
      "comments.approved_at IS NULL"
    else
      nil
    end
    @product = Product.find(params[:product_id]) if params[:product_id]
    @comments = if @product.nil? 
      Comment.paginate(:page => params[:product], :order => "created_at DESC", :conditions => conditions)
    else
      @product.comments.paginate(:product => params[:product], :conditions => conditions)
    end
    
    respond_to do |format|
      format.html
      format.csv  { render :text => @comments.to_csv }
    end
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    announce_comment_removed
    ResponseCache.instance.expire_response(@comment.product.slug)
    redirect_to :back
  end
  
  def edit
    @comment = Comment.find(params[:id])
  end
  
  def update
    @comment = Comment.find(params[:id])
    begin
      TextFilter.descendants.each do |filter| 
        @comment.content_html = filter.filter(@comment.content) if filter.filter_name == @comment.filter_id    
      end
      @comment.update_attributes(params[:comment])
      ResponseCache.instance.clear
      flash[:notice] = "Comment Saved"
      redirect_to :action => :index
    rescue Exception => e
      flash[:notice] = "There was an error saving the comment"
    end
  end
  
  def enable
    @product = Product.find(params[:product_id])
    @product.enable_comments = 1
    @product.save!
    flash[:notice] = "Comments has been enabled for #{@product.title}"
    redirect_to product_index_path
  end
  
  def approve
    @comment = Comment.find(params[:id])
    @comment.approve!
    ResponseCache.instance.expire_response("/products/#{@comment.product.slug}")
    flash[:notice] = "Comment was successfully approved on product #{@comment.product.name}"
    redirect_to :back
  end
  
  def unapprove
    @comment = Comment.find(params[:id])
    @comment.unapprove!
    ResponseCache.instance.expire_response(@comment.product.slug)
    flash[:notice] = "Comment was successfully unapproved on product #{@comment.product.title}"
    redirect_to :back
  end
  
  
  protected
  
    def announce_comment_removed
      flash[:notice] = "The comment was successfully removed from the site."
    end
  
end
