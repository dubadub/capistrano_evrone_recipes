# Capistrano recipes for Rails

We deploy a lot of Rails applications and our developers have to solve similar problems each time during the deployment: how to run workers, how to generate crontab, how to precompile assets faster and so on. This collection of recipes helps us to solve them.

Recipe use:

* [`foreman`][foreman] + [`foreman_export_runitu`][runitu] to generate runit scripts with the Procfile
* [`whenever`][whenever] to generate crontab
* [`nginx`][nginx] as proxy server 

It also consider that you use *rbenv* on the server.

##Installation

    gem 'capistrano_rails_recipes', :require => false

Capfile example:

    require "capistrano_rails_recipes/capistrano"

    set :repository, "git@github.com:..."
    set :application, "my_application"
    set :user, 'deploy'
    set :branch, 'master'
    set :deploy_to, "/path/to/app"
    set :use_sudo, false

    server 'web.example.com', :web, :app, :worker, :crontab
    role :db, 'web.example.com', primary: true

    OR

    task :production do
      role  :web,     "web.example.com"
      role  :app,     "app.example.com"
      role  :crontab, "app.example.com"
      role, :db,      "db.example.com", :primary => true
      role, :worker,  "workers.example.com"
    end

    task :staging do
      server "stage.example.com", :web, :app, :crontab, :db, :worker
    end

As you can see, we use use roles to bind the tasks, and there are some additions to roles and additional roles:

**deploy:setup** creates all necessary folders and symlinks to files:
    config/nginx.conf                     -> /opt/nginx/conf/sites-enabled/my_application
    creates deploy_to/shared/config folder
    creates deploy_to/services folder
    copies config/database.example.yml    -> shared/config/database.yml

Run **deploy:setup** before your first deploy. See below how to configure services.

**web** compiles assets if content of `app/assets` was changed since last deploy (add FORCE=1 to force the assets compilation)

**app** all files from `shared/config` is being symlinked to `current/config` like:

    shared/config/database.yml            -> current/config/database.yml
    shared/config/settings/production.yml -> current/config/settings/production.yml

**crontab** generates crontab with `whenever` gem, only if the content of `config/schedule.rb` was changed (add FORCE=1 to force the crontab generation)

**db** run migrations only if `db/migrate` was changed (add FORCE=1 to force migrations or SKIP_MIGRATION=1 to skip them)

**worker** Procfile exports runit configs to `deploy_to/application/services`

On **deploy:restart** runit workers is being restarted.

You can use some extra `cap` tasks:

* `rails:console` to launch `rails console` on remote server
* `rails:dbconsole` to launch `rails dbconsole` on remote server
* `login` to open SSH session under user `deploy` and switch catalog to Capistrano's `current_path`

**Important**

To run succesfully together with system wide rbenv, all you tasks in Procfile must be started with `rbenv exec`

##Configuring services

To run services just create Procfile in root of your app.

Procfile example:

    sidekiq: rbenv exec bundle exec sidekiq -L sidekiq.log
    web: rbenv exec bundle exec unicorn -c config/unicorn.rb -E production

Also you need to configure runit to monitor deploy_to/services folder. 

##Nginx config file example for Unicorn

    upstream unicorn_my_application {
      server unix:/tmp/unicorn.my_application.sock fail_timeout=0;
    }

    server {
      listen 80;
      server_name web.example.com;
      root deploy_to/current/public;

      location ^~ /assets/ {
        gzip_static on;
        expires max;
        add_header Cache-Control public;
      }

      try_files $uri/index.html $uri @unicorn;
      location @unicorn {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_pass http://unicorn_my_application;
      }

      error_page 500 502 503 504 /500.html;
      client_max_body_size 4G;
      keepalive_timeout 10;
    }

Change **deploy_to** and **my_application** to your actual values.

##Unicorn config file example

    root = "deploy_to/current"
    working_directory root
    pid "#{root}/tmp/pids/unicorn.pid"
    stderr_path "#{root}/log/unicorn.log"
    stdout_path "#{root}/log/unicorn.log"

    listen "/tmp/unicorn.my_application.sock"
    worker_processes 5
    timeout 30

Change **deploy_to** and **my_application** to your actual values.

##Capistrano

Default variables:

    logger.level                   = Capistrano::Logger::DEBUG
    default_run_options[:pty]      = true
    ssh_options[:forward_agent]    = true
    set :bundle_cmd,                 "rbenv exec bundle"
    set :bundle_flags,               "--deployment --quiet --binstubs --shebang ruby-local-exec"
    set :rake,                       -> { "#{bundle_cmd} exec rake" }
    set :keep_releases,              7
    set :scm,                        "git"
    set :user,                       "deploy"
    set :deploy_via,                 :unshared_remote_cache
    set :copy_exclude,               [".git"]
    set :repository_cache,           -> { "#{deploy_to}/shared/#{application}.git" }
    set :normalize_asset_timestamps, false

##Bonus track

To enable silent mode, add `ENV['CAP_SILENT_MODE']` before the `require 'capistrano_evrone_recipes/capistrano'` in your `Capfile`

![silent mode](https://www.evernote.com/shard/s38/sh/4ea45631-93bc-4c03-bad8-f0aa40ca637b/8680b09c40342c6a885212b212b1c746/res/b04ff7c4-b29c-41b2-ab0a-6664cf0b75b9/skitch.png)



[foreman]: https://github.com/ddollar/foreman
[runitu]: https://github.com/evrone/foreman_export_runitu
[whenever]: https://github.com/javan/whenever
[unicorn]: http://unicorn.bogomips.org/
[nginx]: http://nginx.org/
