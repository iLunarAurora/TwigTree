return function(TwigTree)
	local function Portal(targetParent, children)
		local function executePortal(parent: Instance)
			local childHandles = {}

			for childKey, child in pairs(children) do
				if type(childKey) == "string" then
					child.Properties = child.Properties or {}
					child.Properties.Name = childKey
				end

				local handle = TwigTree.mount(child, parent)
				table.insert(childHandles, handle())
			end

			function childHandles:deconstruct()
				for _, child in pairs(childHandles) do
					if typeof(child) == "Instance" then
						child:Destroy()
						--elseif typeof(child) == "table" then
						--	child:Unmount()
					end
				end
			end

			return childHandles
		end

		if typeof(targetParent) == "Instance" then
			return executePortal(targetParent)

		elseif typeof(targetParent) == "table" then
			if targetParent._isComponent then
				-- Component
				local rendered = targetParent()
				if rendered._isTwigClass then
					return executePortal(rendered:mount()())
				elseif typeof(rendered) == "Instance" then
					return executePortal(rendered)
				end
			else
				-- Regular Twig
				return executePortal(targetParent:mount()())
			end
		end

		error('[TwigTree.Portal]: Failed to compile the `targetParent` into an Instance!', 2)
	end
	
	return Portal
end
