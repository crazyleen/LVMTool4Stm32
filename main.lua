
--[[
����ϵͳʱ�䣬��ʱ��
--]]

do
	local sleepdev = 120 --���ߣ��ó�cpu
	local systimedev = 0
	local timedis = 82
	local powdis = 83
	local maintimer = 1
	local sleeptime = 95
	local write = write	--�ֲ���������
	local read = read
	write(84, true, true) --������
	while true do
		write(maintimer, sleeptime)
		local systime,sysms = read(systimedev)
		
		--��ʾʱ��
		write(timedis, systime/60) 
		
		--�����������ʾ��+����
		write(powdis, (systime % 60) * 100 + sysms / 10, true)
		
		write(sleepdev, read(maintimer))
	end
end