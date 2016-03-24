class WebaclsController < ApplicationController

  before_filter :rules_init, only: [:index, :show, :new]

  def rules_init
    @rules = Array.new
    WAF.list_rules(limit: 100).rules.each do |rule|
      # generate array with hashes
      @rules << Hash[name: rule.name, id: rule.rule_id]
      sleep 0.1 # avoid 'Rate exceeded'
    end
  end

  def index
  end

  def show
    @webacl = WAF.get_web_acl(web_acl_id: params[:id])
  end

  def new
  end

  def create
    change_token = WAF.get_change_token().change_token
    @webacl = WAF.create_web_acl({
      name: params[:webacl][:name],
      metric_name: params[:webacl][:metric_name],
      default_action: {
        type: params[:webacl][:default_action_type], # required, accepts BLOCK, ALLOW, COUNT
      },
      change_token: change_token,
    })

    change_token = WAF.get_change_token().change_token
    WAF.update_web_acl({
      web_acl_id: @webacl.web_acl.web_acl_id,
      change_token: change_token,
      updates: [
        {
          action: "INSERT", # required, accepts INSERT, DELETE
          activated_rule: {
            priority: 1,
            rule_id: params[:webacl][:rule_id],
            action: {
              type: params[:webacl][:default_action_type], # required, accepts BLOCK, ALLOW, COUNT
            },
          },
        },
      ],
      default_action: {
        type: params[:webacl][:default_action_type], # required, accepts BLOCK, ALLOW, COUNT
      },
    })

    # show success popup
    respond_to do |format|
      format.any { redirect_to action: 'index' }
      flash[:notice] = 'WAF WebACL has been successfully created!'
    end
  end

  def destroy
    @webacl = WAF.get_web_acl(web_acl_id: params[:id])

    if @webacl.web_acl.rules.any?
      @webacl.web_acl.rules.each do |rule|
        # remove Rule from WebACL
        change_token = WAF.get_change_token().change_token
        WAF.update_web_acl({
          web_acl_id: params[:id],
          change_token: change_token,
          updates: [
            {
              action: "DELETE", # required, accepts INSERT, DELETE
              activated_rule: {
                priority: 1,
                rule_id: rule.rule_id,
                action: { # required
                  type: rule.action.type, # required, accepts BLOCK, ALLOW, COUNT
                },
              },
            },
          ],
          default_action: {
            type: @webacl.web_acl.default_action.type, # required, accepts BLOCK, ALLOW, COUNT
          },
        })
      end
    end

    # remove Rule
    change_token = WAF.get_change_token().change_token
    WAF.delete_web_acl({
      web_acl_id: params[:id],
      change_token: change_token,
    })

    # show success popup
    respond_to do |format|
      format.any { redirect_to action: 'index' }
      flash[:notice] = 'WAF WebACL has been successfully removed!'
    end
  end

end
