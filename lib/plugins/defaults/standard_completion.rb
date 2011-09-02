# -*- coding: utf-8 -*-

require 'set'

module Termtter::Client

  #
  # completion for status ids
  # (This is needed for some plugins)
  #

  public_storage[:status_ids] ||= Set.new

  register_hook(:collect_status_ids, :point => :pre_filter) do |statuses, event|
    statuses.each do |s|
      public_storage[:status_ids].add(s.id)
      public_storage[:status_ids].add(s.in_reply_to_status_id) if s.in_reply_to_status_id
    end
  end

  #
  # completion for user names
  #

  public_storage[:users] ||= Set.new

  register_hook(:collect_user_names, :point => :pre_filter) do |statuses, event|
    statuses.each do |s|
      public_storage[:users].add(s.user.screen_name)
      public_storage[:users] += s.text.scan(/@([a-zA-Z_0-9]*)/i).flatten
    end
  end

  register_hook(:user_names_completion, :point => :completion) do |input|
    if /\/(.*)\s([^\s]*)$/ =~ input
      command_str = $1
      part_of_user_name = $2.gsub(/^@/, '')

      users = 
        if part_of_user_name.nil? || part_of_user_name.empty?
          public_storage[:users].to_a
        else
          public_storage[:users].grep(Regexp.compile("^#{Regexp.quote(part_of_user_name)}", part_of_user_name.downcase == part_of_user_name ? Regexp::IGNORECASE : 0))
        end

      users.map {|u| "/#{command_str} @%s" % u }
    elsif /([^\s]*)/ =~ input
      part_of_user_name = $1.gsub(/^@/, '')

      users = 
        if part_of_user_name.nil? || part_of_user_name.empty?
          public_storage[:users].to_a
        else
          public_storage[:users].grep(Regexp.compile("^#{Regexp.quote(part_of_user_name)}", part_of_user_name.downcase == part_of_user_name ? Regexp::IGNORECASE : 0))
        end

      users.map {|u| "@%s" % u }      
    end
  end

  #
  # completion for hashtags
  #

  public_storage[:hashtags_for_completion] ||= Set.new

  def self.collect_hashtags(text)
    text.force_encoding("UTF-8") if text.respond_to?(:force_encoding)
    public_storage[:hashtags_for_completion] += text.scan(/#([0-9A-Za-z_]+)/u).flatten
  end

  Termtter::RubytterProxy.register_hook(:collect_hashtags, :point => :post_update) do |*args|
    collect_hashtags(args.first)
    args
  end

  register_hook(:collect_hashtags, :point => :pre_filter) do |statuses, event|
    statuses.each do |s|
      collect_hashtags(s.text)
    end
  end

  register_hook(:hashtags_completion, :point => :completion) do |input|
    if /(.*)\s#([^\s]*)$/ =~ input
      command_str = $1
      part_of_hashtag = $2
      ht = public_storage[:hashtags_for_completion]
      (ht.grep(/^#{Regexp.quote(part_of_hashtag)}/) | # prior
       ht.grep(/^#{Regexp.quote(part_of_hashtag)}/i) ).
        map { |i| "#{command_str} ##{i}" }
    end
  end

  #
  # completion for lists
  #

  register_hook(:lists_completion, :point => :completion) do |input|
    if /(.*)\s([^\s]*)$/ =~ input
      command = $1
      part_of_list_name = $2
      public_storage[:lists].
        grep(/#{Regexp.quote(part_of_list_name)}/i).
        map {|u| "#{command} %s" % u }
    end
  end
end
