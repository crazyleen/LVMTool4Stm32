
--------------------------------------------------------------------------------
--                                   定时器中断函数
--------------------------------------------------------------------------------
--[[
定时器中断函数，准备加热状态，每500ms执行一次
--]]
function blink_OnOff_led()
	write(81, 13, 2)
end

--[[
定时器中断函数，暂停模式时每500ms执行一次
--]]
function onPause()
	write(81, 18, 2)
	TimeBlink = not TimeBlink
end

--[[
定时器中断函数，关机后60s停止风扇
--]]
function powerOffFan()
	NeedFan = false
	write(20, 2, false) --停止加热风扇关
end


--工作时间轮
function workerEvery1Sec()
	if ModePause then return end
	
	--无锅提示
	if STime % 3 == 0 then
		local Ptemp,Ppan_exists,Pno_pan_1min,Pan_type = read(20)
		if not Ppan_exists then write(70, 2) end --无锅具
	end
	
	STime = STime - 1
end

--工作时间轮
function workerEvery1Min()
	if ModePause then return end

	TotalTime = TotalTime - 1
end
--------------------------------------------------------------------------------

--[[
蓝牙控制
--]]
function wifienvent() 
	local wificmd = read(140)
	if wificmd == 0 then 
		return
	elseif wificmd == 13 then --关机
		poweroff()
	elseif wificmd == 1 then 	--功率加
		if DisPow < 10 then DisPow = DisPow + 1 write(70, 1) end
		ActPow = DisPow
	elseif wificmd == 2 then 	--功率减
		if DisPow > 1 then DisPow = DisPow - 1 write(70, 1) end
		ActPow = DisPow
	elseif wificmd == 3 then 	--时间加
		if TotalTime < 599 then TotalTime = TotalTime + 1 write(70, 1) end
	elseif wificmd == 4 then	--时间减
		if TotalTime > 1 then TotalTime = TotalTime - 1 write(70, 1) end
	elseif wificmd == 5 then	--蒸煮
		poweron()
		mode_switch(5, setting_steam)
	elseif wificmd == 6 then	--火锅
		poweron()
		mode_switch(6, setting_hot_pot)	
	elseif wificmd == 7 then	--煮粥
		poweron()
		mode_switch(7, setting_congee)	
	elseif wificmd == 8 then 	--炒菜
		poweron()
		mode_switch(8, setting_stir_fry)	
	elseif wificmd == 18 then	--暂停
		pauseCtrl(true)
	elseif wificmd == 19 then	--取消暂停
		pauseCtrl(false)
	elseif wificmd >= 100 and wificmd <= 111 then
		DisPow = wificmd - 100
		ActPow = DisPow
	elseif wificmd >= 1000 and wificmd <  3900 then
		TotalTime = wificmd - 1000
	end
end

--[[
处理按键事件
--]]
function keyevent()
	local key, lp = read(60)
	if key == 13 and not lp then  powerOnOff() return end 	--开关机按键
	if key == KeyMask then return end				--屏蔽按键
	
	if KeyOpt and not lp and ((key >= 1 and key <=4) or (key >= 65 and key < 75)) then 
		ModeManual = true		--手动模式
		TimeBar = true
		--write(70, 1) 			--按键音
		if key == 1 then 		--功率加
			if DisPow < 10 then DisPow = DisPow + 1 write(70, 1) end
		elseif key == 2 then 	--功率减
			if DisPow > 1 then DisPow = DisPow - 1 write(70, 1) end
		elseif key == 3 then 	--时间加
			if TotalTime < 599 then TotalTime = TotalTime + 1 write(70, 1) end
		elseif key == 4 then 	--时间减
			if TotalTime > 1 then TotalTime = TotalTime - 1 write(70, 1) end
		elseif key >= 65 and key <= 75 then		--滑条
			DisPow = key - 64
			write(70, 1)
		end
		ActPow = DisPow		--功率同步
	end

	if KeyOpt and lp and ((key >= 1 and key <=4) or (key >= 65 and key < 75)) then 
		ModeManual = true		--手动模式
		TimeBar = true
		--write(70, 1) 			--按键音
		if key == 1 then 		--功率加
			if DisPow < 10 then DisPow = DisPow + 1 write(70, 1) end
		elseif key == 2 then 	--功率减
			if DisPow > 2 then DisPow = DisPow - 1 write(70, 1) end
		elseif key == 3 then 	--时间加
			if TotalTime < 590 then TotalTime = TotalTime + 10 write(70, 1) end
		elseif key == 4 then 	--时间减
			if TotalTime > 10 then TotalTime = TotalTime - 10 write(70, 1) end
		end
		ActPow = DisPow		--功率同步
	end
	
	if not lp and KeyFunc and key >= 5 and key <= 18 then 
		if key ~= 13 then  KeyMask = key end --开关按键不禁止
		write(70, 1) 			--按键音
		if key == 18 then 		--18暂停
			pauseCtrl(not ModePause)
		elseif key == 5 then 	--5蒸煮
			mode_switch(key, setting_steam)
		elseif key == 6 then 	--6火锅
			mode_switch(key, setting_hot_pot)
		elseif key == 7 then 	--7煮粥
			mode_switch(key, setting_congee)
		elseif key == 8 then 	--8煲汤
			mode_switch(key, setting_boil_soup)
		elseif key == 13 then 	--开关按键
			powerOnOff()
		elseif key == 14 then 	--14烧水
			--mode_switch(key, setting_boil_water)
			mode_switch(key, setting_usercfg)	--用户模式
		elseif key == 17 then 	--17炒菜
			mode_switch(key, setting_stir_fry)
		end
	end
end


--[[
开关机切换
--]]
function powerOnOff()
	if OnOff then 
		--关机
		poweroff()
	else
		poweron()
	end
end

function poweron()
	OnOff = true
	--开机
	KeyFunc = true	--使能功能按键
	KeyOpt = false	--禁止非功能按键
	KeyMask = 18	--禁止暂停按键
	write(70, 1) --按键音
	TimerCrtl(0, 30*1000, false, powerOnOff)	--30s后关机
	TimerCrtl(1, 500, true, blink_OnOff_led)	--500ms闪烁
end

--[[
关机
--]]
function poweroff()
	local write = write
	OnOff = false
	TimerCrtl() --关闭所有定时器
	
	KeyFunc = false
	KeyOpt = false
	KeyMask = 0

	ModeFunc = 0
	ModePause = false
	
	TimeBlink = false
	TimeBar = false
	
	write(70, 0)		--关机声音
	write(80, false)	--关闭所有显示
	write(20, 2, NeedFan) --停止加热风扇开
	TimerCrtl(0, 60*1000, false, powerOffFan)
end

--[[
系统开机初始化
--]]
function start()
	local write = write
	write(70, 0) 	--开机声
	write(80, true) --点亮所有显示
	write(84, true, true) 	--点亮呼吸灯
	write(120, 1000) 		--延时1s
	write(80) 	--熄灭所有显示
	write(84)	--熄灭呼吸灯
end


--[[
暂停控制
state参数： true暂停， false取消暂停
--]]
function pauseCtrl(state)
	if state then 
		ModePause = true
	else 
		ModePause = false
	end
	
	if ModePause then 
		KeyOpt = false
		KeyMask = 0
		TimerCrtl(2, 60*1000, false, powerOnOff)
		TimerCrtl(3, 500, true, onPause)
	else
		KeyMask = ModeFunc
		KeyOpt = true
		TimerCrtl(2)
		TimerCrtl(3)
	end
	write(81, 18, ModePause)
end


--[[
模式切换
--]]
function mode_switch(menu, setting)
	local write = write
	write(81, 0, 3)
	write(81, menu, true)
	ModeFunc = menu
	ModeInit = false
	ModeSet = setting
	ModeManual = false
	ModePause = false
end

--[[
进入下一工作阶段
如果已经是最后一步，则继续最后一步，直至总时间用完
--]]
function configNextStep()
	local localSTime = ModeSet(Mstep)
	if localSTime == nil then 
		STime = TotalTime * 60
	else 
		STime,Temp,LTemp,HTemp,DisPow,ActPow,Duty,Cycle,Htype = ModeSet(Mstep)
		write(70, 2)	--阶段变化声音
	end
end

--[[
工作过程
--]]
function worker()
	local write = write
	if ModePause then 
		write(20, 1, 0, Htype)	--暂停加热
		write(82, TotalTime, TimeBar, TimeBlink)
		write(83, 0)
		return 
	end
	
	if ModeFunc > 0 then
		--模式初始化
		if not ModeInit then
			ModeInit = true
			ModeManual = false
			ModePause = false
			TimeBar = false
			KeyOpt = true
			Mstep = 0
			STime,Temp,LTemp,HTemp,DisPow,ActPow,Duty,Cycle,Htype,TotalTime = ModeSet(Mstep)
			TimerCrtl()	--关闭所有定时器
			TimerCrtl(0, 1000, true, workerEvery1Sec)
			TimerCrtl(1, 60*1000, true, workerEvery1Min)
			write(20, 0, ActPow, Htype)	--加热初始化
			NeedFan = true --标志关机后要开风扇
		end

		--获取信息
		local Ptemp,Ppan_exists,Pno_pan_1min,Pan_type = read(20)
		
		--关机
		if TotalTime <= 0 or Pno_pan_1min then  return powerOnOff() end
		
		if not ModeManual then
		
			do
				local t,temp,ltemp,htemp,dispow,actpow = ModeSet(Mstep) --执行模式函数
				if actpow then
					ActPow = actpow
				end
			end
			
			--时间迁移
			if STime <= 0 then 
				Mstep = Mstep + 1
				configNextStep()
			elseif Temp > 0 then 				--迁移温度
				if Ptemp > Temp then 
					Mstep = Mstep + 1
					configNextStep()
				end
			else
				if Ptemp > HTemp then		--高温，进入下一阶段
					Mstep = Mstep + 1
					configNextStep()
				elseif Ptemp < LTemp then 	--低温，返回上一阶段
					Mstep = Mstep - 1
					configNextStep()
				end
			end
			
			--调功比控制
			if Duty < Cycle then 
				local cycletime = STime % Cycle
				if cycletime < Duty then 
					--加热
					OnDuty = true
				else 
					OnDuty = false				
				end
			end
		end
		
		if not ModeManual and not OnDuty then 
			write(20, 1, 0, Htype)	--暂停加热
		else
			write(20, 1, ActPow, Htype)	--加热
		end
		write(81, ModeFunc, true)
		write(81, 13, true)
		write(82, TotalTime, TimeBar)
		write(83, DisPow)	
	end
end

-----------------------------------------------------------------------------------
--                                      全局变量
-----------------------------------------------------------------------------------

--开关机标志
OnOff = false

--按键屏蔽
KeyOpt = false	--使能非功能按键
KeyFunc = false	--功能按键
KeyMask = 0	--禁止某一按键

--模式功能
ModeFunc = 0		--当前模式
ModeInit = false	--初始化标志
ModeSet = nil		--模式配置函数
ModeManual = false	--手动模式
ModePause = false	--暂停模式

NeedFan = false		--关机后风扇是否要工作30s

TimeBlink = false	--是否显示时间数码管的“ ：”
TimeBar = false		--是否显示timebar

-----------------------------------------------------------------------------------



-----------------------------------------------------------------------------------
--                                     main entry
-----------------------------------------------------------------------------------
do
	local sleepdev = 120 --休眠，让出cpu
	local maintimer = 1
	local write = write
	local read = read

	start()
	
	while true do
		--计算延时时间
		write(maintimer, 100)
		
		--处理按键事件
		keyevent()
		
		--处理wifi事件
		wifienvent()
		
		--定时器更新
		TimerUpdate()
		
		--工作过程
		worker()
		
		--休眠剩余时间
		do
			local sleepMs = read(maintimer)
			--write(83, sleepMs, true) --显示睡眠时间
			if sleepMs <= 100 then write(sleepdev, sleepMs) end
		end
	end
end
