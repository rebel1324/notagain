hook.Add("PlayerFootstep", "realistic_footsteps", function(ply, pos, foot, sound, volume, rf)
	if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:OnGround() then return end
	return true
end)

hook.Add("PlayerStepSoundTime", "realistic_footsteps", function(ply, type, walking)
	if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:OnGround() then return end
	return 9999
end)

if CLIENT then
	local extra = {
		{
			find = {
				"combine",
				"soldier",
				"gasmask",
				"swat",
				"guerilla",
				"urban",
			},
			sounds = {
				"npc/combine_soldier/gear1.wav",
				"npc/combine_soldier/gear2.wav",
				"npc/combine_soldier/gear3.wav",
				"npc/combine_soldier/gear4.wav",
				"npc/combine_soldier/gear5.wav",
				"npc/combine_soldier/gear6.wav",
			},
		},
		{
			find = {
				"police",
				"riot",
				"leet",
				"dod_german",
				"arctic",
				"phoenix",
			},
			sounds = {
				"npc/metropolice/gear1.wav",
				"npc/metropolice/gear2.wav",
				"npc/metropolice/gear3.wav",
				"npc/metropolice/gear4.wav",
				"npc/metropolice/gear5.wav",
				"npc/metropolice/gear6.wav",
			},
		},
		{
			find = {
				"kleiner",
				"magnusson",
				"breen",
				"gman",
			},
			sounds = {
				"npc/footsteps/softshoe_generic6.wav"
			},
		},
		{
			find = {
				"group0%d",
				"hostage",
			},
			sounds = {
				"npc/footsteps/hardboot_generic1.wav",
				"npc/footsteps/hardboot_generic2.wav",
				"npc/footsteps/hardboot_generic3.wav",
				"npc/footsteps/hardboot_generic4.wav",
				"npc/footsteps/hardboot_generic5.wav",
				"npc/footsteps/hardboot_generic6.wav",
				"npc/footsteps/hardboot_generic8.wav",
			},
		},
		{
			find = {
				"eli"
			},
			sounds = {
				"npc/stalker/stalker_footstep_left1.wav",
				"npc/stalker/stalker_footstep_left2.wav",
				"npc/stalker/stalker_footstep_right1.wav",
				"npc/stalker/stalker_footstep_right2.wav",
			},
			play_only = "left",
		},
		{
			find = {
				"eli"
			},
			sounds = {
				"physics/wood/wood_furniture_impact_soft1.wav",
				"physics/wood/wood_furniture_impact_soft2.wav",
				"physics/wood/wood_furniture_impact_soft3.wav",
			},
			pitch = 125,
			random_pitch = 0,
			play_only = "left",
		},
		{
			find = {
				"skeleton"
			},
			sounds = {
				"physics/wood/wood_furniture_impact_soft1.wav",
				"physics/wood/wood_furniture_impact_soft2.wav",
				"physics/wood/wood_furniture_impact_soft3.wav",
			},
			pitch = 175,
			random_pitch = 0.25,
		},
		{
			find = {
				"chell"
			},
			sounds = {
				"npc/stalker/stalker_footstep_left1.wav",
				"npc/stalker/stalker_footstep_left2.wav",
				"npc/stalker/stalker_footstep_right1.wav",
				"npc/stalker/stalker_footstep_right2.wav",
			},
		},
		{
			find = {
				"zombie",
			},
			sounds = {
				"npc/zombie/foot1.wav",
				"npc/zombie/foot2.wav",
				"npc/zombie/foot3.wav",
				"npc/fast_zombie/foot1.wav",
				"npc/fast_zombie/foot2.wav",
				"npc/fast_zombie/foot3.wav",
			},
		}
	}

	local sounds = {}

	for _, name in pairs(sound.GetTable()) do
		if name:EndsWith("StepLeft") or name:EndsWith("StepRight") then
			local data = sound.GetProperties(name)
			if type(data.sound) == "string" then
				data.sound = {data.sound}
			end

			local friendly = name:match("(.+)%."):lower()

			sounds[friendly] = sounds[friendly] or {sounds = {}, pitch = data.pitch, level = data.level, volume = data.volume}

			for _, path in pairs(data.sound) do
				path = path:lower()
				if not table.HasValue(sounds[friendly].sounds, path) then
					table.insert(sounds[friendly].sounds, path)
				end
			end
		end
	end

	local feet = {"left", "right"}

	hook.Remove("Think", "realistic_footsteps")
	timer.Create("realistic_footsteps", 1/30, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:OnGround() then continue end
			for _, which in ipairs(feet) do
				ply.realistic_footsteps = ply.realistic_footsteps or {}
				ply.realistic_footsteps[which] = ply.realistic_footsteps[which] or {}

				ply:SetupBones()
				local id = ply:LookupBone(which == "right" and "valvebiped.bip01_r_toe0" or "valvebiped.bip01_l_toe0")


				local m = ply:GetBoneMatrix(id)

				if not m then continue end
				local scale = ply:GetModelScale() or 1
				local pos = m:GetTranslation()

				local vel = (ply.realistic_footsteps[which].last_pos or pos) - pos
				ply.realistic_footsteps.smooth_vel = ply.realistic_footsteps.smooth_vel or vel
				ply.realistic_footsteps.smooth_vel = ply.realistic_footsteps.smooth_vel + ((vel - ply.realistic_footsteps.smooth_vel) * FrameTime() * 5)
				vel = ply.realistic_footsteps.smooth_vel

				local dir = Vector(0,0,-50)

				local trace = util.TraceLine({start = pos, endpos = pos + dir, filter = {ply}})

				if trace.HitTexture == "TOOLS/TOOLSNODRAW" or trace.HitTexture == "**empty**" then
					trace.Hit = false
				end

				-- if dir is -50 this is required to check if the foot is actualy above player pos
				if pos.z - ply:GetPos().z > 1.5*scale then
					trace.Hit = false
				end

				local volume = math.Clamp(vel:Length()/2, 0, 1)

				debugoverlay.Line(pos, pos + dir * volume, 0.25, trace.Hit and Color(255,0,0,255) or Color(255,255,255,255), true)

				if trace.Hit then

					local data

					if bit.band(util.PointContents(trace.HitPos), CONTENTS_WATER) == CONTENTS_WATER then
						data = sounds.water
					elseif trace.SurfaceProps ~= -1 then
						local name = util.GetSurfacePropName(trace.SurfaceProps)
						data = sounds[name]
						if not data then
							for k,v in pairs(sounds) do
								if k:find(name) then
									data = v
									break
								end
							end
						end

						if not data then
							data = sounds.default
						end
					end

					if data then
						if not ply.realistic_footsteps[which].sound_played then

							local mute = false

							local path = table.Random(data.sounds)

							for name, func in pairs(hook.GetTable().PlayerFootstep) do
								if name ~= "realistic_footsteps" then
									local ret = func(ply, pos, path, volume)
									if ret == true then
										mute = true
										break
									end
								end
							end

							if mute then continue end

							EmitSound(path, pos, ply:EntIndex(), CHAN_BODY, data.volume * volume, data.level, SND_NOFLAGS, math.Clamp((data.pitch / scale) + math.Rand(-10,10), 0, 255))
							ply.realistic_footsteps[which].sound_played = true

							local mdl = ply:GetModel()
							for _, info in pairs(extra) do
								for _, pattern in ipairs(info.find) do
									if mdl:find(pattern) then
										if not info.play_only or info.play_only == which then
											EmitSound(
												table.Random(info.sounds),
												pos,
												ply:EntIndex(),
												CHAN_BODY,
												data.volume * volume * 0.1,
												data.level,
												SND_NOFLAGS,
												math.Clamp(((info.pitch or data.pitch) / scale) + math.Rand(-10,10) * (info.random_pitch or 1), 0, 255)
											)
										end
									end
								end
							end
						end
					end
				else
					ply.realistic_footsteps[which].sound_played = false
				end

				ply.realistic_footsteps[which].last_pos = pos
			end
		end
	end)
end