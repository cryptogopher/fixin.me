class TagsController < ApplicationController
  before_action ->{ @tag = current_user.tags.find_by!(id: params[:id]) },
    only: [:new, :edit, :update, :reposition, :destroy],
    unless: ->{ action_name == "new" && params[:id].nil? }

  before_action except: :index do
    raise AccessForbidden unless current_user.at_least(:active)
  end

  def index
    @tags = current_user.tags.ordered.includes(:supertag, :subtags)
  end

  def new
    @tag = current_user.tags.new(supertag: @tag)
  end

  def create
    @tag = current_user.tags.new(params.expect(Tag::ATTRIBUTES))
    if @tag.save
      @before = @tag.succeeding
      @ancestors = @tag.ancestors
      flash.now.notice = t('.success', tag: @tag)
    else
      render_errors @tag
    end
  end

  def edit
  end

  def update
    if @tag.update(params.except(:supertag_id).expect(Tag::ATTRIBUTES))
      @ancestors = @tag.ancestors
      flash.now.notice = t('.success', tag: @tag)
    else
      render_errors @tag
    end
  end

  def reposition
    tag_params = params.expect(tag: :supertag_id)

    @prev_supertag_id = @tag.supertag_id
    if @tag.update(tag_params)
      @ancestors = Tag.ancestors([@prev_supertag_id, @tag.supertag_id])
        .includes(:subtags)
      @tags = @tag.with_progenies.includes(:subtags)
      @before = @tag.succeeding(true)
    else
      # Until UI blocks all disallowed repositions, render error messages if present.
      flash.now.alert = @tag.errors.full_messages
      render :nothing
    end
  end

  def destroy
    @tag.destroy!
    @ancestors = @tag.ancestors
    flash.now.notice = t('.success', tag: @tag)
  end

  private
end
