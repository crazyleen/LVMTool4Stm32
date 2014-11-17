
-----------------------------------------------------------------------------------
--                                   菜单
-----------------------------------------------------------------------------------
ModeSetting = nil	--菜单配置

ModeStep = 0	--工作阶段
ModeTNow = 0 	--当前系统时间，秒
ModeTStart = 0	--开始工作时间
ModeTStep = 0	--当前阶段开始时间
ModeSecFlg = false	--每秒
ModeMinFlg = false 	--每分钟

BotTem = 0	--底部温度
TopTem = 0	--顶部温度

HeatWater = false	--热水煮标志
MenuWrong = false	--再次煮饭标志
ContinueCook = false 	--连续煮

--计算时间差（秒），最大跨度是24小时
function deltaTime(now, pass)
	local delta = now - pass
	--计算24小时溢出时间
	if delta < 0 then 
		delta = delta + 24*3600 
	end	
	return delta
end

function mode_flg_clear()
	HeatWater = false		--热水煮标志
	MenuWrong = false		--再次煮饭标志
	ContinueCook = false 	--连续煮
	TrouBleMode = false	
	MiShui = -2 			--米水量， -2尚未开始检测，-1检测中，>=0米水量
end

--[[
阶段1检查
在第31s时检查温度设置以下三个标志位：
	MenuWrong 
	ContinueCook 
	HeatWater 
结束返回true，尚未结束返回false
--]]
function mode_check()
--[[
1）检测阶段，若31秒时：
                    ①底部温度在 >= 70℃，取消煮饭后再按开始煮饭的标志MunuWrong_F置位。(所有功能)
                    ②若上盖温度 >= 48℃，连续煮标志ContinueCook_F置位。(所有功能)
                    ③若底部温度在31秒后连续上升 5 个AD值，热水煮标志 HeatWater置位。(所有功能)
--]]
	local botTem,topTem = BotTem,TopTem
	
	--计算该阶段经过的时间
	local passtime = deltaTime(ModeTNow, ModeTStep)
	if passtime < 31 then 
		mode_check_flg = true
		botTemBak = 0
		MenuWrong = false
		ContinueCook = false
		HeatWater = false
	elseif passtime >= 31 and mode_check_flg then 
		mode_check_flg = false
		if botTem >= 70 then MenuWrong = true end	--取消煮饭再按开始煮饭
		if topTem >= 48 then ContinueCook = true end 	--持续煮
		botTemBak = topTem	--保存当前值
	elseif passtime >= 32 then
		if botTem > botTemBak + 5 then HeatWater = true end	--热水煮
		--进入下一个阶段
		return true
	end
	
	return false
end

--[[
工作函数
返回默认的口感，米种，工作时间: mode_worker(true)	
正常工作：mode_worker()
--]]
function mode_worker(init)
	if init then
		ModeStep = 0			--初始化标记
		return ModeSetting(0)	--返回：口感，米种，工作时间
	end
	
	local read = read
	local write = write
	
	--更新当前时间
	local now = read(0)
	--底部、顶部温度
	BotTem,TopTem = read(40)
	
	--初始化阶段
	if ModeStep <= 0 then
		ModeStep = 1		--进入阶段1
		ModeTNow = now		--更新当前时间
		ModeTStep = now		--记录阶段开始时间
		ModeSecFlg = false	--每秒
		ModeMinFlg = false 	--每分钟
		ModeTStart = now	--记录开始工作时间
	end
	
	--秒标志
	if now ~= ModeTNow then ModeSecFlg = true; ModeTNow = now; else ModeSecFlg = false;	end
	--分钟标志
	if ModeSecFlg and (deltaTime(now, ModeTStart) % 60 == 0) then ModeMinFlg = true else ModeMinFlg = false	end

	--总时间流逝
	if ModeMinFlg then ModeLeftT = ModeLeftT - 1 end
	
	local run_again = true
	while run_again do
		run_again = false
		
		--step>0返回：
		--	时间，
		--	底部迁移温度，底部温控，底部加热时间，底部加热周期，
		--  侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
		--	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
		--	是否迁移
		local timeout,botTemOver,botTemCtrl,botDuty,botCycle,
			sideTemOver,sideTemCtrl,sideDuty,sideCycle,
			topTemOver,topTemCtrl,topDuty,topCycle,
			nextstep = ModeSetting(ModeStep)
		
		--进入下一阶段条件：
		--	如果有是否迁移，先执行是否迁移返回true
		--	超时
		--	到达迁移温度
		if (nextstep == true)
			or (timeout <= 0 or deltaTime(ModeTNow,ModeTStep) >= timeout)
			or (botTemOver > 0 and BotTem >= botTemOver)
			or (topTemOver > 0 and TopTem >= topTemOver) then  
			--是否迁移返回true则表示阶段迁移
			ModeStep = ModeStep + 1	--进入下一阶段
			ModeTStep = now 		--记录阶段开始时间
			run_again = true		--立即执行新阶段
		end
		
		--加热控制
		write(20, botTemCtrl, botDuty, botCycle)	--底部
		write(21, sideTemCtrl, sideDuty, sideCycle)	--侧边
		write(22, topTemCtrl,topDuty,topCycle)		--顶部
	
		--工作完成或时间耗尽，进入保温
		if ModeStep > 13 or ModeLeftT <= 0 then
			mode_select(10)
			mode_start()
			break	--该模式结束
		end
	
	end
end


--[[
香甜煮
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode0_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 1,1,43
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
极速煮
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode1_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 1,1,25
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
煮粥
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode2_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 0,1,60
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
稀饭
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode3_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 0,1,30
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
婴儿粥
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode4_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 0,1,120
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
粗粮饭
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode5_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 1,1,60
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
寿司饭
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode6_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 1,1,60
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
蒸煮
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode7_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 0,0,30
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
煲汤
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode8_setting(step)
	if step == 0 then	--初始化阶段
		mode_flg_clear()
		return 0,0,120
	elseif step == 1 then	--阶段1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1

	elseif step == 3 then	--阶段3 吸水2
		--[[
		2）吸水2阶段，若有连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，吸水2迁移时间改为5分钟，调功比为0。
		3）吸水2阶段，若有取消煮饭后再按开始煮饭的标志MenuWrong_F，吸水2迁移时间改为0分钟，调功比为0。
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--阶段4 加热1	
		--4）加热1阶段，若底部温度 > 123℃(BB)，垫米粒标志TrouBleMode_F置位，此时，底部有120℃温度控制。(所有功能)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5）加热1阶段，底部温度 >= 60℃(47) 开始判断米水量计时，(所有功能的米水量等级都是这样判断)
		--			  当底部温度 >= 90℃(80) 和 上盖温度 >=85℃(63) 同时间达到时，结束米水量判断。
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--米水检测中
			MiShuiT = ModeTNow	--记录当前时间
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			水米量等级			0					1				2				3			
判定依据	加热1 时间（偏硬）	< 120s				< 180s			< 360s			>= 360s			
			加热1 时间（偏软）	< 120s				< 240s			< 360s			>= 360s			
			加热1 时间（适中）	< 120s				< 180s			< 360s			>= 360s			
			--]]
			MiShui = deltaTime(ModeTNow, MiShuiT)
			if MiShui < 120 then
				MiShui = 0
			elseif (MiShui < 180 and (DisKG % 10) ~= 2) or (MiShui < 240 and (DisKG % 10) == 2) then
				MiShui = 1
			elseif MiShui < 360 then
				MiShui = 2
			else
				MiShui = 3
			end
		end
		
		--6）加热1阶段，判断出米水量后，加热1调功比为 14/16。（香甜煮）
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17）垫米粒TrouBleMode_F米水量等级强制为2等级，热水煮 HeatWater_F、取消煮饭后再按开始煮饭MunuWrong_F、连续煮ContinueCook_F的米水量等级强制为3等级。(所有功能)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--阶段5 停止1
		--7）停止1阶段，如果是平衡温度点迁移，停止5秒钟，调功比为2。
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--阶段6 加热2
		--[[
		米水量等级					0					1				2				3
		阶段6(加热2)调功比			8					8				9				10			
		阶段6(加热2)底部迁移温度	105℃ 				105℃ 			105℃ 			110℃ ( A5H )			
		--]]
		local botTemOver,botDuty
		if MiShui <= 1 then
			botTemOver = 105
			botDuty = 8
		elseif MiShui == 2 then
			botTemOver = 105
			botDuty = 9	
		elseif MiShui == 3 then
			botTemOver = 110
			botDuty = 10		
		end
		
		--8）加热2阶段，若有垫米粒标志 TroubleMode_F，上盖迁移温度改为 89℃(6B)，此时，满足底部或上盖任一条件即可向下一阶段迁移。(所有功能)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--阶段7 停止2
		
		--[[
		米水量等级		0				1			2			3
		阶段7(停止2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9）停止2阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 3分钟。(所有功能)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--阶段8 持续沸腾1
		local botTemOver,botDuty
		
		--[[
		米水量等级					0					1				2				3
		阶段8(维持沸腾1) 调功		6					6				7				8			
		阶段8(维持沸腾1) 底部迁移	108℃ 				110℃			115℃			120℃ 			
		--]]
		if MiShui == 0 then
			botDuty = 6
			botTemOver = 108
		elseif MiShui == 1 then
			botDuty = 6
			botTemOver = 110
		elseif MiShui == 2 then
			botDuty = 7
			botTemOver = 115
		elseif MiShui == 3 then
			botDuty = 8
			botTemOver = 120
		end
		
		--10）沸腾1阶段，连续煮标志ContinueCook_F或热水煮标志 HeatWater_F，调功比为6。
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11）沸腾1阶段，若有连续煮标志 ContinueCook_F 或 垫米粒标志 TroubleMode_F，同时若调功比 < 7，同调功比改为 7/16。
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12）沸腾1阶段，若进入沸腾阶段的时间 >= 900秒，底部调功改为 9/16。
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		--[[
		13）焖饭前等待阶段，若有热水煮标志 HeatWater_F或取消煮饭后再按开始煮饭的标志MunuWrong_F，迁移时间改为 2分钟。
		14）焖饭前等待阶段，若有垫米粒标志 TroubleMode_F，迁移时间改为 2分钟，调功比为5；底部温控125℃。
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--阶段11 焖1
		--15）焖饭阶段判断，米水量等级 <=1 时，焖饭总时间改为 8分钟，若米水量等级 >1，则焖饭1、2、3阶段迁移时间为查表时间。
		--16）焖饭1阶段，若米水量等级 >=3 时，调功比为1/16。
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--阶段11 焖2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--阶段11 焖3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end


--[[
热饭
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode9_setting(step)
	local nextstep = false
		
	if step == 0 then	--初始化阶段
		HeatWater = false	--热水煮标志
		MenuWrong = false	--再次煮饭标志
		ContinueCook = false 	--连续煮
		TrouBleMode = false	
		return 0,0,25
	elseif step == 1 then	--阶段1 check
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--阶段2 吸水1
	
	elseif step == 3 then	--阶段3 吸水2
		
	elseif step == 4 then	--阶段4 加热1
		return 15*60,85,115,8,16,0,0,0,0,130,108,16,32,false
	elseif step == 5 then	--阶段5 停止1
		
	elseif step == 6 then	--阶段6 加热2
		
	elseif step == 7 then	--阶段7 停止2
		
	elseif step == 8 then	--阶段8 持续沸腾1
		return 21*60,160,95,8,16,0,0,0,0,130,108,16,32,false
	elseif step == 9 then	--阶段9 持续沸腾2
		
	elseif step == 10 then	--阶段10 焖前等待
		
	elseif step == 11 then	--阶段11 焖1
		return 2*60,130,95,4,16,0,0,0,0,130,108,16,32,false
	elseif step == 12 then	--阶段11 焖2
		
	elseif step == 13 then	--阶段11 焖3
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
保温
step==0返回：口感，米种，总时间
step >0返回：
	时间，
	底部迁移温度，底部温控，底部加热时间，底部加热周期，
	侧边迁移温度，侧边温控，侧边加热时间，侧边加热周期，
	上盖迁移温度,上盖温控，上盖加热时间，上盖加热周期，
	是否迁移
--]]
function mode10_setting(step)
	if step == 0 then	--初始化阶段
		ModeWarmT = 0
		return 0,0,3600
	end
	
	--每分钟更新一次
	if ModeMinFlg then
		ModeLeftT = 3600	--刷新剩余时间
		ModeWarmT = deltaTime(ModeTNow, ModeTStart) / 60	--计算保温时间
	end
	
	local botTemOver,botTemCtrl,botDuty,botCycle,
		sideTemOver,sideTemCtrl,sideDuty,sideCycle,
		topTemOver,topTemCtrl,topDuty,topCycle
	
	local bottem = BotTem
	local toptem = TopTem
	if bottem >= 70 then 
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 0, 16		--底部加热，温控69，调功比0/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 2, 32	--侧边加热，温控69，调功比2/32
	elseif bottem >= 69 then
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 0, 16		--底部加热，温控69，调功比0/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 18, 32	--侧边加热，温控69，调功比18/32	
	elseif bottem >= 68 then
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 0, 16		--底部加热，温控69，调功比0/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 22, 32	--侧边加热，温控69，调功比22/32	
	elseif bottem >= 66 then
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 1, 16		--底部加热，温控69，调功比1/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 26, 32	--侧边加热，温控69，调功比26/32	
	else
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 2, 16		--底部加热，温控69，调功比2/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 30, 32	--侧边加热，温控69，调功比30/32	
	end
	
	if toptem > bottem + 0x14 then
		topTemOver,topTemCtrl,topDuty,topCycle = 1, 69, 2, 16		--上盖加热，温控69，调功比4/32
	else
		topTemOver,topTemCtrl,topDuty,topCycle = 1, 69, 30, 32		--上盖加热，温控69，调功比20/32
	end
	
	--25*3600=90000 时间跨度最大只有一天，这里表示用不超时
	return 90000,botTemOver,botTemCtrl,botDuty,botCycle,
		sideTemOver,sideTemCtrl,sideDuty,sideCycle,
		topTemOver,topTemCtrl,topDuty,topCycle,false
end

function worker_select(menu)
	if menu == 0 then
		ModeSetting = mode0_setting
	elseif menu == 1 then
		ModeSetting = mode1_setting
	elseif menu == 2 then
		ModeSetting = mode2_setting
	elseif menu == 3 then
		ModeSetting = mode3_setting
	elseif menu == 4 then
		ModeSetting = mode4_setting
	elseif menu == 5 then
		ModeSetting = mode5_setting
	elseif menu == 6 then
		ModeSetting = mode6_setting
	elseif menu == 7 then
		ModeSetting = mode7_setting
	elseif menu == 8 then
		ModeSetting = mode8_setting
	elseif menu == 9 then
		ModeSetting = mode9_setting
	else
		ModeSetting = mode10_setting
	end
	
	return mode_worker
end