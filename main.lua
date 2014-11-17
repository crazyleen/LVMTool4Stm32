
--[[
测试系统时间，定时器
--]]

do
	local sleepdev = 120 --休眠，让出cpu
	local systimedev = 0
	local timedis = 82
	local powdis = 83
	local maintimer = 1
	local sleeptime = 95
	local write = write	--局部变量加速
	local read = read
	write(84, true, true) --呼吸灯
	while true do
		write(maintimer, sleeptime)
		local systime,sysms = read(systimedev)
		
		--显示时间
		write(timedis, systime/60) 
		
		--功率数码管显示秒+毫秒
		write(powdis, (systime % 60) * 100 + sysms / 10, true)
		
		write(sleepdev, read(maintimer))
	end
end