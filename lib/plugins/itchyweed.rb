# -*- coding: utf-8 -*-
# author: bgnori bgnori@gmail.com, @bgnori(twitter), bgnori.tumblr.com
#
# Thanks to tumblife!(mitukiii)
# 
# http://kagit.tumblr.com/post/20218426153
# 人のなにげないツイート、タンブラーにポストするのキモいですよ
# Twitter /@honishi
#
#
#

require 'oauth'
require 'tumblife' 


module ItchyWeed

  OAUTH_CONSUMER_KEY = 'n4JPEf6xvuRRaq1intRhtv44wCss3vBkEeBIIcrNbylcDhkzxS'
  OAUTH_SECRET_KEY = 'VU74CFGESeSdqxpR85WCHEqfAY5yxXBeT7kwr5RPebolEJ4WXG'
  TOKEN_FILE_PATH = "~/.termtter/tumblrtoken"
  
  def format_a_tweet(tw)
    "%s(@%s): %s (id: %s) \n"% [tw[:user][:name], tw[:user][:screen_name], tw[:text], tw[:id]]
  end
  
  def format_conv(tweets)
    tweets.sort_by {|k, v| k }.map {|k, v| format_a_tweet(v) }.join ''
  end
  
  def myinit(purge)
    access_token_token = ''
    access_token_secret = ''

    if not purge and File.exist?(File.expand_path(TOKEN_FILE_PATH))
      p 'reading token from file.'
      $base_hostname, access_token_token, access_token_secret = File.read(File.expand_path(TOKEN_FILE_PATH)) \
                                                                  .split(/\r?\n/).map(&:chomp)
    else
      p 'getting toke from site.'
      consumer = OAuth::Consumer.new(
          OAUTH_CONSUMER_KEY, #Termtter::Crypt.decrypt(OAUTH_CONSUMER_KEY),
          OAUTH_SECRET_KEY, #Termtter::Crypt.decrypt(OAUTH_SECRET_KEY),
          :site => 'https://www.tumblr.com')
    
      # xAuth access-token URL:
      # POST https://www.tumblr.com/oauth/access_token 
    
      ui = create_highline
      $base_hostname = ui.ask('tumblr blog url, without http:// i.e. "bgnori.tumblr.com" etc.: ')
      username = ui.ask('tumblr user name(email): ')
      password = ui.ask('tumblr password: '){ |q| q.echo = false }
  
      # http://stackoverflow.com/questions/3159907/ruby-xauth-support
      access_token = consumer.get_access_token(
          nil, 
          {}, 
          { :x_auth_mode => 'client_auth', 
            :x_auth_username => username,
            :x_auth_password => password
          })
  
      open(File.expand_path(TOKEN_FILE_PATH),"w") do |f|
        f.puts $base_hostname
        f.puts access_token.token
        f.puts access_token.secret
      end
      access_token_token = access_token.token
      access_token_secret = access_token.secret
    end
    Tumblife.configure do |config|
      config.consumer_key = OAUTH_CONSUMER_KEY
      config.consumer_secret = OAUTH_SECRET_KEY
      config.oauth_token = access_token_token
      config.oauth_token_secret = access_token_secret
    end
    return Tumblife.client
  end

  module Termtter::Client
    marked = {}
    register_command(
      :name => :tinit,
      :help => ['tinit', 'authorize client'],
      :exec => lambda {|arg|
        p arg
        $tclient = myinit(arg.strip != '')
      }
    )
    register_command(
      :name => :tstat,
      :help => ['tstat', 'show client status'],
      :exec => lambda {|arg|
        p 'cleint is ready for'
        p $tclient.info_user
      }
    )
    register_command(
      :name => :tmark,
      :help => ['tmark msg', 'marking tweet for tumblr chat(conversation) post'],
      :exec => lambda {|arg|
        tweet = Termtter::API.twitter.call_rubytter_or_use_cache('show', arg)
        marked.update(arg => tweet)
        p "marked tweet %s by %s(@%s)"%[tweet[:text], tweet[:user][:name], tweet[:user][:screen_name]]
      }
    )
    register_command(
      :name => :tshow,
      :help => ['tshow ', 'show marked tweets for tumblr chat(conversation) post'],
      :exec => lambda {|arg|
      for tw in marked.values
        p format_a_tweet(tw)
      end
    }
    )
    register_command(
      :name => :tunmark,
      :help => ['tunmakr', 'unmark tweet for tumblr chat(conversation) post'],
      :exec => lambda {|arg|
        marked.delete(arg)
      }
    )
    register_command(
      :name => :tpost,
      :help => ['tpost', 'post tweets to tumblr as chat(conversation) post'],
      :exec => lambda {|arg|
        p 'tpost posting ...'
        $tclient.create_post($base_hostname,
          params={
            :type => 'chat',
            :tags => 'itchy weed, termtter, twitter',
            :conversation =>('%s'%format_conv(marked)),
          }
        )
        marked = {}
      }
    )
  end
  
 end 
