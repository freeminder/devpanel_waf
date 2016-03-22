class IpsetsController < ApplicationController

  before_filter :waf_init

  def waf_init
    @waf = Aws::WAF::Client.new(region: "us-west-1")

    @ip_sets = Array.new
    @waf.list_ip_sets({
      limit: 100,
    }).ip_sets.each do |ip_set|
      @ip_sets << ip_set
    end

    # generate array with hashes
    @ipsets = Array.new
    @ip_sets.each do |ip_set|
      @ipsets << Hash[name: ip_set.name, id: ip_set.ip_set_id, cidr: @waf.get_ip_set(ip_set_id: ip_set.ip_set_id).ip_set.ip_set_descriptors]
    end
  end

  def index
  end

  def new
  end

  def create
    change_token = @waf.get_change_token().change_token
    ip_set_id = @waf.create_ip_set({
      name: params[:name],
      change_token: change_token,
    }).ip_set.ip_set_id

    change_token = @waf.get_change_token().change_token
    @waf.update_ip_set({
      ip_set_id: ip_set_id,
      change_token: change_token,
      updates: [
        {
          action: "INSERT", # required, accepts INSERT, DELETE
          ip_set_descriptor: {
            type: "IPV4", # required, accepts IPV4
            value: params[:cidr],
          },
        },
      ],
    })
  end

end
