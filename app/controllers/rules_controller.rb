class RulesController < ApplicationController

  before_filter :waf_init

  def waf_init
    @waf = Aws::WAF::Client.new(
      region: "us-west-1",
      # credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
      # access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      # secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )

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

  def show
    @rule  = @waf.get_rule(rule_id: params[:id])
    @ipset = @waf.get_ip_set(ip_set_id: @rule.rule.predicates.first.data_id) if @rule.rule.predicates.any?
  end

  def destroy
    @rule = @waf.get_rule(rule_id: params[:id])
    change_token = @waf.get_change_token().change_token

    if @rule.rule.predicates.any?
      @rule.rule.predicates.each do |e|
        @waf.update_rule({
          rule_id: params[:id],
          change_token: change_token,
          updates: [
            {
              action: "DELETE",
              predicate: {
                negated: true,
                type: "IPMatch",
                data_id: @waf.get_ip_set(ip_set_id: e.data_id),
              },
            },
          ],
        })
      end
    end

    @waf.delete_rule({
      rule_id: params[:id],
      change_token: change_token,
    })

    # show success popup
    respond_to do |format|
      format.any { redirect_to action: 'index' }
      flash[:notice] = 'WAF Rule has been successfully removed!'
    end
  end

end
