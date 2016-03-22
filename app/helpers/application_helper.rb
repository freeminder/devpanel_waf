module ApplicationHelper
	def menu_link(label, url, active = false, options = nil)
		# active = controller && (params[:controller].starts_with? controller)
		# active = params[:action] == action if active && action
		# active = item_name == @submenu

		content_tag :li, class: (active ? 'active' : '') do
			link_to label, url, options
		end
	end

	def blank_stub(content)
		if content.blank?
			'<i> ( No content posted. ) </i>'.html_safe
		else
			content
		end
	end
end
