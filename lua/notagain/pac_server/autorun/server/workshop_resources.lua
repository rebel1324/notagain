if game.SinglePlayer() then return end

resource.AddWorkshop("546392647") -- Media Player

if engine.ActiveGamemode() == "lambda" then return end

resource.AddWorkshop("104482086") -- Precision Tool (Not on Server).

do
	local map_content = {
		ze_ffvii_mako_reactor_v5_3 = {"307755108"},
		gm_bluehills_test3 = {"243902601"},
		gm_abstraction_extended = {"734919940"},
	}

	local map = game.GetMap():lower()

	if map_content[map] then
		for _, id in ipairs(map_content[map]) do
			resource.AddWorkshop(id)
		end
	end
end

