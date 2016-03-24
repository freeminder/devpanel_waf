class RulesController < ApplicationController

  before_filter :ipsets_init, only: [:index, :new]

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
    @rule   = WAF.get_rule(rule_id: params[:id])

    @ipsets = Array.new
    if @rule.rule.predicates.any?
      @rule.rule.predicates.each do |e|
        @ipsets << WAF.get_ip_set(ip_set_id: e.data_id)
      end
    end
  end

  def new
  end

  def create
    change_token = WAF.get_change_token().change_token
    @rule = WAF.create_rule({
      name: params[:rule][:name],
      metric_name: params[:rule][:metric_name],
      change_token: change_token,
    })

    change_token = WAF.get_change_token().change_token
    WAF.update_rule({
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

  def destroy
    @rule = WAF.get_rule(rule_id: params[:id])

    if @rule.rule.predicates.any?
      @rule.rule.predicates.each do |e|
        # # remove descriptor from IPSet
        # @ipset = WAF.get_ip_set(ip_set_id: e.data_id)
        # if @ipset.ip_set.ip_set_descriptors.any?
        #   @ipset.ip_set.ip_set_descriptors.each do |descriptor|
        #     change_token = WAF.get_change_token().change_token
        #     WAF.update_ip_set({
        #       ip_set_id: e.data_id,
        #       change_token: change_token,
        #       updates: [
        #         {
        #           action: "DELETE", # required, accepts INSERT, DELETE
        #           ip_set_descriptor: {
        #             type: descriptor.type, # required, accepts IPV4
        #             value: descriptor.value, # required
        #           },
        #         },
        #       ],
        #     })
        #   end
        # end
        # remove IPSet from Rule
        change_token = WAF.get_change_token().change_token
        WAF.update_rule({
          rule_id: params[:id],
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

    # remove Rule
    change_token = WAF.get_change_token().change_token
    WAF.delete_rule({
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
