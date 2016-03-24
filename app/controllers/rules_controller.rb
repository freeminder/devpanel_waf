class RulesController < ApplicationController

  before_filter :waf_init, only: [:index, :new, :show]

  def waf_init
    @waf = Aws::WAF::Client.new

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


  def index
  end

  def new
  end

  def create
    @waf = Aws::WAF::Client.new
    change_token = @waf.get_change_token().change_token
    @rule = @waf.create_rule({
      name: params[:rule][:name],
      metric_name: params[:rule][:metric_name],
      change_token: change_token,
    })

    change_token = @waf.get_change_token().change_token
    @waf.update_rule({
      rule_id: @rule.rule.rule_id,
      change_token: change_token,
      updates: [
        {
          action: "INSERT", # required, accepts INSERT, DELETE
          predicate: {
            negated: true,
            type: "IPMatch", # required, accepts IPMatch, ByteMatch, SqlInjectionMatch, SizeConstraint
            # type: params[:rule][:type],
            data_id: params[:rule][:ip_set_id],
          },
        },
      ],
    })

    # show success popup
    respond_to do |format|
      format.any { redirect_to action: 'index' }
      flash[:notice] = 'WAF Rule has been successfully created!'
    end
  end

  def show
    @rule   = @waf.get_rule(rule_id: params[:id])

    @ipsets = Array.new
    if @rule.rule.predicates.any?
      @rule.rule.predicates.each do |e|
        @ipsets << @waf.get_ip_set(ip_set_id: e.data_id)
      end
    end
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
