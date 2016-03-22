set :rvm_ruby_version, '2.2.1'
set :default_env, { path: "/usr/local/rvm/gems/ruby-2.2.1/bin:/usr/local/rvm/gems/ruby-2.2.1@global/bin:/usr/local/rvm/rubies/ruby-2.2.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/rvm/bin", 
	rvm_bin_path: '/usr/local/rvm/gems/ruby-2.2.1@global/bin', 
	bundle_cmd: "/usr/local/rvm/gems/ruby-2.2.1@global/bin/bundle", 
	bundle_dir: "/usr/local/rvm/gems/ruby-2.2.1",
	gem_home: "/usr/local/rvm/gems/ruby-2.2.1",
	gem_path: "/usr/local/rvm/gems/ruby-2.2.1:/usr/local/rvm/gems/ruby-2.2.1@global"
}

require 'capistrano/rvm'
require "capistrano/bundler"

server 'ec2-52-90-49-206.compute-1.amazonaws.com', user: 'deploy', roles: %w{app}


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

