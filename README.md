# AWS WAF API demo for devPanel

This README would normally document whatever steps are necessary to get the application up and running.


## System dependencies

* Ruby version >= 2.0

* Nginx, Apache or similar web server

* [Phusion Passenger](https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/) or similar application server 

* SQLite

## Configuration

config/local_env.yml should exist and contain:

    # AWS auth
    AWS_REGION             'your_AWS_REGION'
    AWS_ACCESS_KEY_ID:     'your_AWS_ACCESS_KEY_ID'
    AWS_SECRET_ACCESS_KEY: 'your_AWS_SECRET_ACCESS_KEY'
    # secrets.yml
    SECRET_KEY_BASE: 'yoursecretkey'

## Installation

run in the devpanel_waf dir to install the dependencies:

    bundle install

## Database initialization

    rake db:setup

## Deployment instructions

Upload devpanel_waf.tar.gz to the server, unpack it, change dir to devpanel_waf and run in the shell "touch tmp/restart.txt" - 
it will restart application server with the newest version of devpanel_waf.
Also there is configured Capistrano, so just change the configurations in config/deploy/*.rb with appropriate environment
and then deploy it via "cap staging deploy" or "cap production deploy".


## License

Please refer to [LICENSE](LICENSE).
