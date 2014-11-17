
------------------------------------------------------------------------------------
--                                 用户模式
------------------------------------------------------------------------------------


function setting_userpow(power)
	if power <= 0 then
		return 0
	elseif power <= 120 then	--120W
		return 1
	elseif power <= 300 then	--300W
		return 2
	elseif power <= 500 then	--500W
		return 3	
	elseif power <= 800 then	--800W
		return 4
	elseif power <= 1000 then	--1000W
		return 5
	elseif power <= 1200 then	--1200W
		return 6
	elseif power <= 1400 then	--1400W
		return 7
	elseif power <= 1600 then	--1600W
		return 8
	elseif power <= 1800 then	--1800W
		return 9
	else						--2100W
		return 10
	end
end

--[[
用户配置模式
返回值：时间s,迁移温度,低温,高温,显示功率,实际功率,周期内加热时间s,加热周期s,加热类型,总时间min
STime,Temp,LTemp,HTemp,DisPow,ActPow,Duty,Cycle,Htype,TotalTime = setting_usercfg(Mstep)
--]]
function setting_usercfg(step)
	local heat_type = 1 --加热类型
	local totaltime = 60 --总时间min
	local func,argc,argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9
	while true do
		func,argc,argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9 = read(888,step)
		if not func then return 0,0,0,0,0,0 end	--最后一步
		if func == 20015 then
				--提醒
				userfunc_alarm(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
				step = step + 1
				Mstep = step
		elseif func == 2014 then
			--关机
			poweroff()
			return
		else
			func = setting_userfunc(func)
			if not func then return end	--没有对应函数 
			break
		end
	end

	local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)

	actPow = setting_userpow(actPow)
	
	return stime,temp,ltemp,htemp,actPow,actPow,20,20,heat_type,totaltime
end

--[[
用户配置函数编码
--]]
function setting_userfunc(func)
	if func == 20011 then
		return userfunc_heat
	elseif func == 20012 then
		return userfunc_heat_temp
	elseif func == 20013 then
		return userfunc_keep
	end
end

--[[
用户配置函数：加热到某个温度

2)	加热到某个温度
以设定的功率加热到某个温度，温度到达时自动进入下一个步骤
接口编码为20012，有2个参数，参数为温度，功率。
local func,argc,argv0,argv1 = 20012,2,temp,power

返回：时间，迁移温度，低温，高温，功率
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_heat_temp(temp,power)
	return 3600,temp,0,0,power
end

--[[
用户配置函数：加热一段时间

1)	加热一段时间
以设定的功率持续加热一段时间, 时间用完时自动进入下一个步骤
接口编码为20011，有2个参数，参数为时间，功率。
local func,argc,argv0,argv1 = 20011,2,time,power

返回：时间，迁移温度，低温，高温，功率
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_heat(stime,power)
	return stime*60,500,0,0,power
end

--[[
用户配置函数：恒温加热

3)	恒温加热
以设定的功率定温在某个温度，时间用完时自动进入下一个步骤。
接口编码为20013，有3个参数，参数为时间，温度，功率。
local func,argc,argv0,argv1,argv2 = 20013,3,time,temp,power

返回：时间，迁移温度，低温，高温，功率
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_keep(stime,temp,power)
	--获取信息
	local device_temp = read(20)
	
	if device_temp > temp then 				--温度过高
		return stime*60,500,0,0,0,0			--停止加热
	else
		return stime*60,500,0,0,power	--重新开始加热
	end
end

--[[
1.	蜂鸣器提醒
local func,argc,argv0,argv1 = 20015, 2, 1, 0
2.	手机提醒
local func,argc,argv0,argv1 = 20015, 2, 0, 1

返回：时间，迁移温度，低温，高温，功率
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_alarm(argv0,argv1)
	if argv0 == 1 and argv1 == 0 then
		write(70, 0)	--蜂鸣器提醒
	elseif argv0 == 0 and argv1 == 1 then
		write(70, 0)	--手机提醒
	end
	
	--为了延时500ms
	write(120, 500)
	
	return 0,0,0,0,0
end






