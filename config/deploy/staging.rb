set :rvm_ruby_version, '2.2.1'
set :default_env, { path: "/usr/local/rvm/gems/ruby-2.2.1/bin:/usr/local/rvm/gems/ruby-2.2.1@global/bin:/usr/local/rvm/rubies/ruby-2.2.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/rvm/bin", 
	rvm_bin_path: '/usr/local/rvm/gems/ruby-2.2.1@global/bin', 
	bundle_cmd: "/usr/local/rvm/gems/ruby-2.2.1@global/bin/bundle", 
	bundle_dir: "/usr/local/rvm/gems/ruby-2.2.1",
	gem_home: "/usr/local/rvm/gems/ruby-2.2.1",
	gem_path: "/usr/local/rvm/gems/ruby-2.2.1:/usr/local/rvm/gems/ruby-2.2.1@global"
}
# SSHKit.config.command_map[:rake] = "#{fetch(:default_env)[:rvm_bin_path]}/rvm ruby-#{fetch(:rvm_ruby_version)} do bundle exec rake"
# SSHKit.config.command_map[:bundle] = "#{fetch(:default_env)[:bundle_cmd]}"
# SSHKit.config.command_map[:bundle] = "#{fetch(:default_env)[:rvm_bin_path]/ruby}"

require 'capistrano/rvm'
require "capistrano/bundler"

# Simple Role Syntax
# ==================
# Supports bulk-adding hosts to roles, the primary server in each group
# is considered to be the first unless any hosts have the primary
# property set.	Don't declare `role :all`, it's a meta role.

# role :app, %w{deploy@example.com}
# role :web, %w{deploy@example.com}
# role :db,	%w{deploy@example.com}


# Extended Server Syntax
# ======================
# This can be used to drop a more detailed server definition into the
# server list. The second argument is a, or duck-types, Hash and is
# used to set extended properties on the serns500549.ip-192-99-47.netver.

server 'ec2-52-90-49-206.compute-1.amazonaws.com', user: 'deploy', roles: %w{app}

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult[net/ssh documentation](http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start).
#
# Global options
# --------------
#	set :ssh_options, {
#		keys: %w(/home/rlisowski/.ssh/id_rsa),
#		forward_agent: false,
#		auth_methods: %w(password)
#	}
#
# And/or per server (overrides global)
# ------------------------------------
# server 'example.com',
#	 user: 'user_name',
#	 roles: %w{web app},
#	 ssh_options: {
#		 user: 'user_name', # overrides user setting above
#		 keys: %w(/home/user_name/.ssh/id_rsa),
#		 forward_agent: false,
#		 auth_methods: %w(publickey password)
#		 # password: 'please use keys'
#	 }

# namespace :assets do
#	 desc "Precompile assets locally and then rsync to web servers"
#	 task :precompile do
#		 on roles(:app) do
#			 rsync_host = host.to_s # this needs to be done outside run_locally in order for host to exist
#			 run_locally do
#				 with rails_env: fetch(:stage) do
#					 execute :bundle, "exec rake assets:precompile"
#				 end
#				 execute "rsync -av --delete ./public/assets/ #{fetch(:user)}@#{rsync_host}:#{shared_path}/public/assets/"
#				 execute "rm -rf public/assets"
#				 # execute "rm -rf tmp/cache/assets" # in case you are not seeing changes
#			 end
#		 end
#	 end
# end

namespace :assets do
	desc "Precompile assets at app servers"
	task :precompile do
		on roles(:app) do
			within release_path do
				with rails_env: :production do
					execute :bundle, "exec rake assets:precompile"
				end
			end
			execute :touch, release_path.join('tmp/restart.txt')
		end
	end
end

namespace :bundle do
	desc "Do bundle install without deployment at app servers"
	task :install do
		on roles(:app) do
			within release_path do
				with rails_env: :production do
					execute :bundle, "install --no-deployment"
				end
			end
			execute :touch, release_path.join('tmp/restart.txt')
		end
	end
end

