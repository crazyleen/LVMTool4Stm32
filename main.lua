--[[
电饭煲程序
--]]


--显示
DisFunc = 1
DisLed = 0
DisMenu = 0
DisHeng = 0
DisKG = 0
DisMZ = 0
DisGL = 0
DisGJ = 0
DisVoice = 0
DisTimeT = 10
DisTimeM = 0


--状态
ModeState = 0	--菜单状态， 0菜单选择，1工作，2预约设置，3口感设置，4米种设置，5系统时间设置
ModeWorker = nil	--工作函数，工作过程中每隔100ms调用一次
ModeMenu = 0	--当前菜单
ModePreT = 420 	--预设时间 7:00
ModeLeftT = 0 	--剩余时间
ModeWarmT = 0 	--保温时间


--[[
开始工作
设置显示
关闭所有定时器
--]]
function mode_start()
	TimerCrtl()		--关闭所有定时器
	ModeState = 1	--工作状态
	DisFunc = 0		--功能灭
	DisLed = 1000	--开始led常亮
	DisGL = 0	--锅轮不亮
	DisMenu = ModeMenu + 100	--菜单常亮
	DisKG = DisKG % 10	--口感不闪
	DisMZ = DisMZ % 10	--米种不闪
	DisTimeT = 13	--显示剩余时间
	DisHeng = 3 	--横条动画
	DisGJ = 2	--锅具动画
	
	if ModeMenu == 10 then
		--保温显示
		DisTimeT = 14	
		DisHeng = DisMenu 	--横条单亮
		DisGJ = 0			--锅具灭
	elseif ModeMenu == 0 then	--香甜煮
		DisLed = 1010
	elseif ModeMenu == 1 then	--极速煮
		DisLed = 1100
	elseif ModeMenu == 2 then	--煮粥
		DisLed = 1001
	end
end

--[[
模式选择
menu: 数值，选择相应菜单
设置显示
关闭所有定时器
--]]
function mode_select(menu)
	--menu取值范围[0,10]
	menu = menu % 100 % 11 
	while menu < 0 do menu = menu + 11 end
	
	DisFunc = 1		--功能亮
	DisLed = 2000	--开始led闪烁
	DisTimeT = 10	--显示系统时间
	ModeState = 0	--菜单选择状态

	--更新数据	
	DisMenu = 400 + menu
	DisHeng = 200 + menu
	DisGL = 0
	DisGJ = 0
	
	TimerCrtl()		--关闭所有定时器
	
	--当前菜单，则不更新口感米种
	if menu == ModeMenu then 
		DisKG = DisKG % 10
		DisMZ = DisMZ % 10
		return 
	end
	
	ModeMenu = menu	
	--获取菜单的口感、米种
	ModeWorker = worker_select(menu)
	DisKG,DisMZ,ModeLeftT = ModeWorker(true)
end

--设置功能按键处理
function keySetting(key, lp)
	if ModeState == 1 then return end
	
	if not lp and key == 0x06 then 
		--进入设置状态
		
		DisTimeT = 10 	--系统时间
		DisMenu = (DisMenu % 10) + 100	--菜单不闪
		DisHeng = (DisHeng % 10) + 100
		DisKG = DisKG % 10		--口感不闪
		DisMZ = DisMZ % 10		--米种不闪
		if ModeState == 2 and DisKG > 0 then
			--进入口感选择
			ModeState = 3		
			DisKG = DisKG % 10 + 30	--口感闪烁			
		elseif (ModeState == 2 or ModeState == 3) and DisMZ > 0 then
			--进入米种选择
			ModeState = 4
			DisMZ = DisMZ % 10 + 30	--米种闪烁
		else
			--进入预约时间
			ModeState = 2
			DisTimeT = 21 --闪烁的预约时间	
		end
	elseif lp and key == 0x06 then
		--系统时间设置
		ModeState = 5
		DisTimeT = 20 	--系统时间闪烁
		DisMenu = (DisMenu % 10) + 100	--菜单不闪
		DisHeng = (DisHeng % 10) + 100
		DisKG = DisKG % 10		--口感不闪
		DisMZ = DisMZ % 10		--米种不闪		
	elseif ModeState == 2 then 
		--处理设置
		
		--预约时间的滑条
		if key == 0x03 or key == 0x07 then 
			--滑条+
			if not lp then
				ModePreT = ModePreT + 1
			else
				ModePreT = ModePreT + 10
			end
			while ModePreT >= 1440 do  ModePreT = ModePreT - 1440 end	--24小时循环
			DisTimeT = DisTimeT % 10 + 10 --时间不闪烁
			TimerCrtl(0, 1000, false, distime_blink)	--1s后预约时间再次闪烁
			return
		elseif key == 0x05 or key == 0x08 then
			--滑条-
			if not lp then
				ModePreT = ModePreT - 1
			else
				ModePreT = ModePreT - 10
			end		
			while ModePreT < 0 do  ModePreT = ModePreT + 1440 end	--24小时循环
			DisTimeT = DisTimeT % 10 + 10	--时间不闪烁
			TimerCrtl(0, 1000, false, distime_blink)	--1s后预约时间再次闪烁
			return
		end		
	elseif ModeState == 3 then
		--口感设置的滑条
		if key == 0x03 or key == 0x07 then 
			--滑条+
			DisKG = DisKG + 1
			if DisKG >= 34 then DisKG = 31 end
		elseif key == 0x05 or key == 0x08 then
			--滑条-
			DisKG = DisKG - 1
			if DisKG <= 30 then DisKG = 33 end			
		end		
	elseif ModeState == 4 then
		--米种设置的滑条
		if key == 0x03 or key == 0x07 then 
			--滑条+
			DisMZ = DisMZ + 1
			if DisMZ >= 34 then DisMZ = 31 end
		elseif key == 0x05 or key == 0x08 then
			--滑条-
			DisMZ = DisMZ - 1
			if DisMZ <= 30 then DisMZ = 33 end			
		end			
	elseif ModeState == 5 then
		--系统时间设置的滑条
		if key == 0x03 or key == 0x07 then 
			--滑条+
			DisTimeT = 10 	--系统时间不闪烁
			local Systime,micros = read(0)
			Systime = Systime / 60
			if not lp then
				Systime = Systime + 1
			else
				Systime = Systime + 10
			end		
			while Systime >= 1440 do  Systime = Systime - 1440 end	--24小时循环
			write(0, Systime)	--更新时间
			TimerCrtl(0, 1000, false, distime_blink)	--1s后预约时间再次闪烁
		elseif key == 0x05 or key == 0x08 then
			--滑条-
			DisTimeT = 10 	--系统时间不闪烁
			local Systime,micros = read(0)
			Systime = Systime / 60
			if not lp then
				Systime = Systime - 1
			else
				Systime = Systime - 10
			end		
			while Systime < 0 do  Systime = Systime + 1440 end	--24小时循环
			write(0, Systime)	--更新时间	
			TimerCrtl(0, 1000, false, distime_blink)	--1s后预约时间再次闪烁
		end			
	end
end

--[[
定时器0中断函数，设置时间时按键触发后1s再次闪烁时间
--]]
function distime_blink()
	--预约时间闪烁
	if ModeState == 2 then DisTimeT = 21 end 
	if ModeState == 5 then DisTimeT = 20 end 
end

--[[
定时器0中断函数，预约时间检查
时间到达后进入工作状态
--]]
function prebook_run()
	local Systime,micros = read(0)
	Systime = Systime / 60
	if Systime == ModePreT then
		mode_start()
	end
end

--[[
预约开始工作
关闭所有定时器
定时器0每隔3s循环检查是否时间到期
设置显示
--]]
function prebook_start()
	TimerCrtl()		--关闭所有定时器
	TimerCrtl(0, 3000, true, prebook_run)	--每隔3s检查一下是否到时
	
	--设置显示
	ModeState = 1	--工作状态
	DisFunc = 0		--功能灭
	DisLed = 1000	--开始led常亮
	DisGL = 0	--锅轮不亮
	DisGJ = 0	--锅具不亮
	DisMenu = ModeMenu + 100	--菜单常亮
	DisHeng = DisMenu
	DisKG = DisKG % 10	--口感不闪
	DisMZ = DisMZ % 10	--米种不闪	
	DisTimeT = 11 --预约时间不闪	
end

--[[
按键处理，根据ModeState选取不同操作
--]]
function keyEvent()
	--get key
	local key,lp = read(60)
	if key == 0 then return end
	
	--煮粥+极速(组合按键) 语音开启与关闭
	if key == 0x35 then DisVoice = (DisVoice + 1) % 2 end

	--工作状态，只相应取消按键
	if ModeState == 1 then  
		if key == 0x04 then 
			if ModeMenu == 10 then
				mode_select(0)	
			else
				mode_select(ModeMenu)
			end
		end
		return
	end
		
	--功能按键，非工作状态，选择下一个菜单
	if key == 0x02 and ModeState ~= 1 then  mode_select(ModeMenu+1) return end
	
	--设置
	if key == 0x06 or (ModeState > 1 and key ~= 4 and key >= 3 and key <= 8) then return keySetting(key, lp) end
	
	if not lp then
		--取消/保温
		if key == 0x04 then
			if ModeState == 0 then 
				--进入保温
				mode_select(10)
				mode_start()
			else
				mode_select(ModeMenu)	
			end
		elseif key == 0x01 then
			if ModeState == 2 then
				--预约定时
				prebook_start()
			elseif ModeState == 5 then
				--退出系统时间设置
				mode_select(ModeMenu)	
			else
				mode_start()
			end
		elseif key == 0x03 or key == 0x07 then 
			--滑条+
			mode_select(ModeMenu+1)
		elseif key == 0x05 or key == 0x08 then
			--滑条-
			mode_select(ModeMenu-1)
		elseif key == 0x31 then
			--极速煮
			mode_select(1)
			mode_start()
		elseif key == 0x32 then
			--香甜煮
			mode_select(0)
			mode_start()
		elseif key == 0x34 then
			--煮粥
			mode_select(2)
			mode_start()
		end		
	else
		--长按按键

	end 
end

--[[
更新显示
--]]
function update_dis()
	--10系统时间，11预约时间，12结束时间，13剩余时间,14保温时间
	local timett = DisTimeT % 10
	if timett == 0 then 
		local Systime,micros = read(0)
		DisTimeM = Systime / 60
	elseif timett == 1 or timett == 2 then
		DisTimeM = ModePreT
	elseif timett == 3 then
		DisTimeM = ModeLeftT
	elseif timett == 4 then
		DisTimeM = ModeWarmT
	end
	
	if ModeState == 5 then
		--设置时间，不显示菜单
		write(80, DisFunc, DisLed, 0, 0, 0,
			0, 0, 0, DisVoice, DisTimeT, DisTimeM)
	else
		--正常显示
		write(80, DisFunc, DisLed, DisMenu, DisHeng, DisKG,
			DisMZ, DisGL, DisGJ, DisVoice, DisTimeT, DisTimeM)		
	end
end

-----------------------------------------------------------------------------------
--                                     main entry
-----------------------------------------------------------------------------------
do
	local sleepdev = 120 --休眠，让出cpu
	local maintimer = 1
	local write = write
	local read = read
	write(0, 800)
	mode_select(1)
	mode_select(0)
	while true do
		--计算延时时间
		write(maintimer, 100)
	
		keyEvent()
		
		--定时器更新
		TimerUpdate()
		
		--工作函数
		if ModeWorker and ModeState == 1 then 
			ModeWorker() 
		end
		
		--更新显示
		update_dis()

		--休眠剩余时间
		do
			local sleepMs = read(maintimer)
			--if true then ModeLeftT = 100 - sleepMs; update_dis(); end --测试，显示休眠时间
			if sleepMs <= 100 then write(sleepdev, sleepMs) end
		end
	end
end
