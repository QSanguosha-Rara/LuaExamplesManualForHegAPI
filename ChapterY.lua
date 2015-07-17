--[[
	国战技能速查手册（Y区）
	技能索引：
	疑城、遗计、遗志、英魂、鹰扬、英姿、勇决 
]]--
--[[
	疑城
	相关武将：阵-徐盛
	描述：每当与你势力相同的一名角色成为【杀】的目标后，你可以令该角色摸一张牌，然后其弃置一张牌。 
	引用：
	状态：
]]
--[[
	遗计
	相关武将：标-郭嘉
	描述：每当你受到1点伤害后，你可以观看牌堆顶的两张牌，然后将其中的一张牌交给一名角色，将另一张牌交给一名角色。 
	引用：
	状态：
]]

luaYiji = sgs.CreateTriggerSkill{
	name = "luaYiji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)	
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		local trigger_list = {}
		for i = 1, damage.damage, 1 do
			table.insert(trigger_list, self:objectName())
		end
		return table.concat(trigger_list,",")
	end,
	on_cost = function(self, event, room, player, data)
		return room:askForSkillInvoke(player, self:objectName(), data)
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		room:broadcastSkillInvoke(self:objectName())
		room:notifySkillInvoked(player, self:objectName())
		local _guojia = sgs.SPlayerList()
		_guojia:append(player)
		local yiji_cards = room:getNCards(2, false)
		local move = sgs.CardsMoveStruct(yiji_cards, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
		local moves = sgs.CardsMoveList()
		moves:append(move)
		room:notifyMoveCards(true, moves, false, _guojia)
		room:notifyMoveCards(false, moves, false, _guojia)
		local origin_yiji = sgs.IntList()
		for _, id in sgs.qlist(yiji_cards) do
			origin_yiji:append(id)
		end
		while room:askForYiji(player, yiji_cards, self:objectName(), true, false, true, -1, room:getAlivePlayers()) do
			local move = sgs.CardsMoveStruct(sgs.IntList(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
			for _, id in sgs.qlist(origin_yiji) do
				if room:getCardPlace(id) ~= sgs.Player_DrawPile then
					move.card_ids:append(id)
					yiji_cards:removeOne(id)
				end
			end
			origin_yiji = sgs.IntList()
			for _, id in sgs.qlist(yiji_cards) do
				origin_yiji:append(id)
			end	
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			if not player:isAlive() then return end
		end
		if not yiji_cards:isEmpty() then
			local move = sgs.CardsMoveStruct(yiji_cards, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(), self:objectName(), nil))
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, _guojia)
			room:notifyMoveCards(false, moves, false, _guojia)
			for _, id in sgs.qlist(yiji_cards) do
				player:obtainCard(sgs.Sanguosha:getCard(id), false)
			end
		end
	end,
}

--[[
	遗志
	相关武将：阵-姜维
	描述：副将技，此武将牌上单独的阴阳鱼个数-1；副将技，若你的主将有“观星”，此“观星”描述中的X视为5，否则你视为拥有“观星”。 
	引用：
	状态：
	备注：阴阳鱼减少不在技能里
]]

LuaYizhi = sgs.CreateTriggerSkill{
	name = "LuaYizhi",
	relate_to_place = "deputy",
	frequency = sgs.Skill_Compulsory;
	events = {sgs.GameStart,sgs.EventPhaseStart},
	can_preshow = false,
	can_trigger = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self) then return false end
		if event == sgs.GameStart then
			local guanxing = sgs.Sanguosha:getSkill("luaGuanxing")
			if guanxing and guanxing:inherits("TriggerSkill") then
				local guanxing_trigger = sgs.Sanguosha:getTriggerSkill("luaGuanxing")
				room:getThread():addTriggerSkill(guanxing_trigger)
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if not player:hasSkill("luaGuanxing") then
                return "luaGuanxing"
			end
		end
	end,
	on_cost = function(self,event,room,player,data)
		return false
	end,
}

--[[
	英魂
	相关武将：标-孙坚、势-孙策
	描述：准备阶段开始时，若你已受伤，你可以选择一项：1.令一名其他角色摸X张牌，然后该角色弃置一张牌；2.令一名其他角色摸一张牌，然后该角色弃置X张牌。（X为你已损失的体力值） 
	引用：
	状态：
]]

LuaYinghun = sgs.CreatePhaseChangeSkill{
	name = "LuaYinghun",
	can_preshow = false,
	can_trigger = function(self,event,room,target,data)
		if not target or target:isDead() or not target:hasSkill(self:objectName()) then return false end
		if target:getPhase() == sgs.Player_Start and target:isWounded() then
			return self:objectName()
		end
	end,
	on_cost = function(self,event,room,player,data)
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yinghun-invoke", true, true)
		if to then
			local d = sgs.QVariant()
			d:setValue(to)
			player:setTag("yinghun_target",d)
			return true
		end
	end,
	on_phasechange = function(self,sunjian)
		local room = sunjian:getRoom()
		local to = sunjian:getTag("yinghun_target"):toPlayer()
		if to then
			local x = sunjian:getLostHp()

			if x == 1 then
				room:broadcastSkillInvoke(self:objectName(), 1, sunjian)

				to:drawCards(1)
				room:askForDiscard(to, self:objectName(), 1, 1, false, true)
			else
				to:setFlags("YinghunTarget")
				local choice = room:askForChoice(sunjian, self:objectName(), "d1tx+dxt1")
				to:setFlags("-YinghunTarget")
				if choice == "d1tx" then
					room:broadcastSkillInvoke(self:objectName(), 2, sunjian)

					to:drawCards(1)
					room:askForDiscard(to, self:objectName(), x, x, false, true)
				else
					room:broadcastSkillInvoke(self:objectName(), 1, sunjian)

					to:drawCards(x)
					room:askForDiscard(to, self:objectName(), 1, 1, false, true)
				end
			end
		end
		return false
	end,
}

--[[
	鹰扬
	相关武将：势-孙策
	描述：每当你拼点的牌亮出后，你可以令此牌的点数于此次拼点中+3或-3。 
	引用：
	状态：
]]
--[[
	英姿
	相关武将：标-周瑜、势-孙策
	描述：摸牌阶段，你可以额外摸一张牌。 
	引用：
	状态：
]]

LuaYingzi = sgs.CreateDrawCardsSkill{
	name = "LuaYingzi",
	frequency = sgs.Skill_Frequent,
	can_preshow = true,

	on_cost = function(self,event,room,player,data)
		if not player or player:isDead() or not player:hasSkill(self:objectName()) then return false end
		if player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
	end,
	draw_num_func = function(self,player,n)
		return n + 1
	end,
}

--[[
	勇决
	相关武将：势-糜夫人
	描述：每当与你势力相同的一名角色使用的【杀】因结算完毕而置入弃牌堆时，若此【杀】为该角色于出牌阶段内使用的首张牌，其可以将此牌移动的目标区域改为其手牌。 
	引用：
	状态：
]]
