class IpsetsController < ApplicationController

  before_filter :waf_init

  def waf_init
    @waf = Aws::WAF::Client.new
  end

  def index
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
      sleep 1 # avoid 'Rate exceeded'
    end
  end

  def show
    @ipset = @waf.get_ip_set(ip_set_id: params[:id])
  end

  def new
  end

  def create
    change_token = @waf.get_change_token().change_token
    ip_set_id = @waf.create_ip_set({
      name: params[:ipset][:name],
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
            type: params[:ipset][:type], # required, accepts IPV4
            value: params[:ipset][:cidr],
          },
        },
      ],
    })

    # show success popup
    respond_to do |format|
      format.any { redirect_to action: 'index' }
      flash[:notice] = 'WAF IPSet has been successfully created!'
    end
  end

  def destroy
    @ipset = @waf.get_ip_set(ip_set_id: params[:id])
    change_token = @waf.get_change_token().change_token

    # remove IPSet from Rule
    @waf.list_rules(limit: 100).rules.each do |r|
      rule = @waf.get_rule(rule_id: r.rule_id)
      if rule.rule.predicates.any?
        rule.rule.predicates.each do |e|
          if e.data_id == @ipset.ip_set.ip_set_id
            @waf.update_rule({
              rule_id: rule.rule.rule_id,
              change_token: change_token,
              updates: [
                {
                  action: "DELETE",
                  predicate: {
                    negated: true,
                    type: "IPMatch",
                    data_id: "#{@waf.get_ip_set(ip_set_id: e.data_id)}",
                  },
                },
              ],
            })
          end
        end
      end
    end

    # remove IPSet
    @waf.delete_ip_set({
      ip_set_id: params[:id],
      change_token: change_token,
    })

    # show success popup
    respond_to do |format|
      format.any { redirect_to action: 'index' }
      flash[:notice] = 'WAF IPSet has been successfully removed!'
    end
  end


end
