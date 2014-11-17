
-----------------------------------------------------------------------------------
--                                   软件定时器
-----------------------------------------------------------------------------------
--[[
软件定时器使用示例：
设置定时器0在60s后执行一次poweroff函数：	TimerCrtl(0, 60*1000, false, poweroff)
设置定时器1间隔500ms不断执行ledblink函数：	TimerCrtl(1, 500, true, ledblink)
停止定时器1：		TimerCrtl(1)
停止所有定时器： 	TimerCrtl()
--]]

--[[
脚本软定时器6个，从0,到5
Tn：	定时器号码
Tcnt：	倒数计时毫秒
Tflag：	控制标志，nil为关闭，false为单次，true为循环
Thandler：	中断函数
--]]
function TimerCrtl(Tn, Tcnt, Tflag, Thandler)
	if Tn == 0 then 
		Tcnt0 = Tcnt			--倒数计时毫秒
		Tcntkeep0 = Tcnt		--备份
		Tflag0 = Tflag			--控制标志，0为关闭，1为单次，2为循环
		Thandler0 = Thandler	--中断函数
	elseif Tn == 1 then 
		Tcnt1 = Tcnt
		Tcntkeep1 = Tcnt
		Tflag1 = Tflag
		Thandler1 = Thandler	
	elseif Tn == 2 then 
		Tcnt2 = Tcnt
		Tcntkeep2 = Tcnt
		Tflag2 = Tflag
		Thandler2 = Thandler		
	elseif Tn == 3 then 
		Tcnt3 = Tcnt
		Tcntkeep3 = Tcnt
		Tflag3 = Tflag
		Thandler3 = Thandler		
	elseif Tn == 4 then 
		Tcnt4 = Tcnt
		Tcntkeep4 = Tcnt
		Tflag4 = Tflag
		Thandler4 = Thandler	
	elseif Tn == 5 then 
		Tcnt5 = Tcnt
		Tcntkeep5 = Tcnt
		Tflag5 = Tflag
		Thandler5 = Thandler	
	else
		Tflag0 = nil
		Tflag1 = nil
		Tflag2 = nil
		Tflag3 = nil
		Tflag4 = nil
		Tflag5 = nil
	end
end

--[[
在主循环中每100ms调用一次
--]]
function TimerUpdate()
	if Tflag0 ~= nil then
		Tcnt0 = Tcnt0 - 100
		if Tcnt0 <= 0 then
			if Thandler0 then Thandler0() end
			if Tflag0 then Tcnt0 = Tcntkeep0 else Tflag0 = nil end
		end
	end
	
	if Tflag1 ~= nil then
		Tcnt1 = Tcnt1 - 100
		if Tcnt1 <= 0 then
			if Thandler1 then Thandler1() end
			if Tflag1 then Tcnt1 = Tcntkeep1 else Tflag1 = nil end
		end
	end
	
	if Tflag2 ~= nil then
		Tcnt2 = Tcnt2 - 100
		if Tcnt2 <= 0 then
			if Thandler2 then Thandler2() end
			if Tflag2 then Tcnt2 = Tcntkeep2 else Tflag2 = nil end
		end
	end
	
	if Tflag3 ~= nil then
		Tcnt3 = Tcnt3 - 100
		if Tcnt3 <= 0 then
			if Thandler3 then Thandler3() end
			if Tflag3 then Tcnt3 = Tcntkeep3 else Tflag3 = nil end
		end
	end
	
	if Tflag4 ~= nil then
		Tcnt4 = Tcnt4 - 100
		if Tcnt4 <= 0 then
			if Thandler4 then Thandler4() end
			if Tflag4 then Tcnt4 = Tcntkeep4 else Tflag4 = nil end
		end
	end
	
	if Tflag5 ~= nil then
		Tcnt5 = Tcnt5 - 100
		if Tcnt5 <= 0 then
			if Thandler5 then Thandler5() end
			if Tflag5 then Tcnt5 = Tcntkeep5 else Tflag5 = nil end
		end
	end
end
-------------------------------------------------------------------------------
