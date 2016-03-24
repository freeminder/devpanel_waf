class IpsetsController < ApplicationController

  before_filter :ipsets_init, only: [:index]

  def ipsets_init
    @ip_sets = Array.new
    WAF.list_ip_sets({
      limit: 100,
    }).ip_sets.each do |ip_set|
      @ip_sets << ip_set
    end

    # generate array with hashes
    @ipsets = Array.new
    @ip_sets.each do |ip_set|
      @ipsets << Hash[name: ip_set.name, id: ip_set.ip_set_id, cidr: WAF.get_ip_set(ip_set_id: ip_set.ip_set_id).ip_set.ip_set_descriptors]
      sleep 0.1 # avoid 'Rate exceeded'
    end
  end

  def index
  end

  def show
    @ipset = WAF.get_ip_set(ip_set_id: params[:id])
  end

  def new
  end

  def create
    change_token = WAF.get_change_token().change_token
    ip_set_id = WAF.create_ip_set({
      name: params[:ipset][:name],
      change_token: change_token,
    }).ip_set.ip_set_id

    change_token = WAF.get_change_token().change_token
    WAF.update_ip_set({
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
    @ipset = WAF.get_ip_set(ip_set_id: params[:id])

    # remove IPSet from Rule
    change_token = WAF.get_change_token().change_token
    WAF.list_rules(limit: 100).rules.each do |r|
      rule = WAF.get_rule(rule_id: r.rule_id)
      if rule.rule.predicates.any?
        rule.rule.predicates.each do |e|
          if e.data_id == @ipset.ip_set.ip_set_id
            WAF.update_rule({
              rule_id: rule.rule.rule_id,
              change_token: change_token,
              updates: [
                {
                  action: "DELETE",
                  predicate: {
                    negated: true,
                    type: e.type,
                    data_id: e.data_id,
                  },
                },
              ],
            })
          end
        end
      end
    end

    # remove descriptor from IPSet
    if @ipset.ip_set.ip_set_descriptors.any?
      @ipset.ip_set.ip_set_descriptors.each do |e|
        change_token = WAF.get_change_token().change_token
        WAF.update_ip_set({
          ip_set_id: params[:id],
          change_token: change_token,
          updates: [
            {
              action: "DELETE", # required, accepts INSERT, DELETE
              ip_set_descriptor: {
                type: e.type, # required, accepts IPV4
                value: e.value, # required
              },
            },
          ],
        })
      end
    end

    # remove IPSet
    change_token = WAF.get_change_token().change_token
    WAF.delete_ip_set({
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
