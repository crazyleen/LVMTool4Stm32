--[[
�緹�ҳ���
--]]


--��ʾ
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


--״̬
ModeState = 0	--�˵�״̬�� 0�˵�ѡ��1������2ԤԼ���ã�3�ڸ����ã�4�������ã�5ϵͳʱ������
ModeWorker = nil	--��������������������ÿ��100ms����һ��
ModeMenu = 0	--��ǰ�˵�
ModePreT = 420 	--Ԥ��ʱ�� 7:00
ModeLeftT = 0 	--ʣ��ʱ��
ModeWarmT = 0 	--����ʱ��


--[[
��ʼ����
������ʾ
�ر����ж�ʱ��
--]]
function mode_start()
	TimerCrtl()		--�ر����ж�ʱ��
	ModeState = 1	--����״̬
	DisFunc = 0		--������
	DisLed = 1000	--��ʼled����
	DisGL = 0	--���ֲ���
	DisMenu = ModeMenu + 100	--�˵�����
	DisKG = DisKG % 10	--�ڸв���
	DisMZ = DisMZ % 10	--���ֲ���
	DisTimeT = 13	--��ʾʣ��ʱ��
	DisHeng = 3 	--��������
	DisGJ = 2	--���߶���
	
	if ModeMenu == 10 then
		--������ʾ
		DisTimeT = 14	
		DisHeng = DisMenu 	--��������
		DisGJ = 0			--������
	elseif ModeMenu == 0 then	--������
		DisLed = 1010
	elseif ModeMenu == 1 then	--������
		DisLed = 1100
	elseif ModeMenu == 2 then	--����
		DisLed = 1001
	end
end

--[[
ģʽѡ��
menu: ��ֵ��ѡ����Ӧ�˵�
������ʾ
�ر����ж�ʱ��
--]]
function mode_select(menu)
	--menuȡֵ��Χ[0,10]
	menu = menu % 100 % 11 
	while menu < 0 do menu = menu + 11 end
	
	DisFunc = 1		--������
	DisLed = 2000	--��ʼled��˸
	DisTimeT = 10	--��ʾϵͳʱ��
	ModeState = 0	--�˵�ѡ��״̬

	--��������	
	DisMenu = 400 + menu
	DisHeng = 200 + menu
	DisGL = 0
	DisGJ = 0
	
	TimerCrtl()		--�ر����ж�ʱ��
	
	--��ǰ�˵����򲻸��¿ڸ�����
	if menu == ModeMenu then 
		DisKG = DisKG % 10
		DisMZ = DisMZ % 10
		return 
	end
	
	ModeMenu = menu	
	--��ȡ�˵��ĿڸС�����
	ModeWorker = worker_select(menu)
	DisKG,DisMZ,ModeLeftT = ModeWorker(true)
end

--���ù��ܰ�������
function keySetting(key, lp)
	if ModeState == 1 then return end
	
	if not lp and key == 0x06 then 
		--��������״̬
		
		DisTimeT = 10 	--ϵͳʱ��
		DisMenu = (DisMenu % 10) + 100	--�˵�����
		DisHeng = (DisHeng % 10) + 100
		DisKG = DisKG % 10		--�ڸв���
		DisMZ = DisMZ % 10		--���ֲ���
		if ModeState == 2 and DisKG > 0 then
			--����ڸ�ѡ��
			ModeState = 3		
			DisKG = DisKG % 10 + 30	--�ڸ���˸			
		elseif (ModeState == 2 or ModeState == 3) and DisMZ > 0 then
			--��������ѡ��
			ModeState = 4
			DisMZ = DisMZ % 10 + 30	--������˸
		else
			--����ԤԼʱ��
			ModeState = 2
			DisTimeT = 21 --��˸��ԤԼʱ��	
		end
	elseif lp and key == 0x06 then
		--ϵͳʱ������
		ModeState = 5
		DisTimeT = 20 	--ϵͳʱ����˸
		DisMenu = (DisMenu % 10) + 100	--�˵�����
		DisHeng = (DisHeng % 10) + 100
		DisKG = DisKG % 10		--�ڸв���
		DisMZ = DisMZ % 10		--���ֲ���		
	elseif ModeState == 2 then 
		--��������
		
		--ԤԼʱ��Ļ���
		if key == 0x03 or key == 0x07 then 
			--����+
			if not lp then
				ModePreT = ModePreT + 1
			else
				ModePreT = ModePreT + 10
			end
			while ModePreT >= 1440 do  ModePreT = ModePreT - 1440 end	--24Сʱѭ��
			DisTimeT = DisTimeT % 10 + 10 --ʱ�䲻��˸
			TimerCrtl(0, 1000, false, distime_blink)	--1s��ԤԼʱ���ٴ���˸
			return
		elseif key == 0x05 or key == 0x08 then
			--����-
			if not lp then
				ModePreT = ModePreT - 1
			else
				ModePreT = ModePreT - 10
			end		
			while ModePreT < 0 do  ModePreT = ModePreT + 1440 end	--24Сʱѭ��
			DisTimeT = DisTimeT % 10 + 10	--ʱ�䲻��˸
			TimerCrtl(0, 1000, false, distime_blink)	--1s��ԤԼʱ���ٴ���˸
			return
		end		
	elseif ModeState == 3 then
		--�ڸ����õĻ���
		if key == 0x03 or key == 0x07 then 
			--����+
			DisKG = DisKG + 1
			if DisKG >= 34 then DisKG = 31 end
		elseif key == 0x05 or key == 0x08 then
			--����-
			DisKG = DisKG - 1
			if DisKG <= 30 then DisKG = 33 end			
		end		
	elseif ModeState == 4 then
		--�������õĻ���
		if key == 0x03 or key == 0x07 then 
			--����+
			DisMZ = DisMZ + 1
			if DisMZ >= 34 then DisMZ = 31 end
		elseif key == 0x05 or key == 0x08 then
			--����-
			DisMZ = DisMZ - 1
			if DisMZ <= 30 then DisMZ = 33 end			
		end			
	elseif ModeState == 5 then
		--ϵͳʱ�����õĻ���
		if key == 0x03 or key == 0x07 then 
			--����+
			DisTimeT = 10 	--ϵͳʱ�䲻��˸
			local Systime,micros = read(0)
			Systime = Systime / 60
			if not lp then
				Systime = Systime + 1
			else
				Systime = Systime + 10
			end		
			while Systime >= 1440 do  Systime = Systime - 1440 end	--24Сʱѭ��
			write(0, Systime)	--����ʱ��
			TimerCrtl(0, 1000, false, distime_blink)	--1s��ԤԼʱ���ٴ���˸
		elseif key == 0x05 or key == 0x08 then
			--����-
			DisTimeT = 10 	--ϵͳʱ�䲻��˸
			local Systime,micros = read(0)
			Systime = Systime / 60
			if not lp then
				Systime = Systime - 1
			else
				Systime = Systime - 10
			end		
			while Systime < 0 do  Systime = Systime + 1440 end	--24Сʱѭ��
			write(0, Systime)	--����ʱ��	
			TimerCrtl(0, 1000, false, distime_blink)	--1s��ԤԼʱ���ٴ���˸
		end			
	end
end

--[[
��ʱ��0�жϺ���������ʱ��ʱ����������1s�ٴ���˸ʱ��
--]]
function distime_blink()
	--ԤԼʱ����˸
	if ModeState == 2 then DisTimeT = 21 end 
	if ModeState == 5 then DisTimeT = 20 end 
end

--[[
��ʱ��0�жϺ�����ԤԼʱ����
ʱ�䵽�����빤��״̬
--]]
function prebook_run()
	local Systime,micros = read(0)
	Systime = Systime / 60
	if Systime == ModePreT then
		mode_start()
	end
end

--[[
ԤԼ��ʼ����
�ر����ж�ʱ��
��ʱ��0ÿ��3sѭ������Ƿ�ʱ�䵽��
������ʾ
--]]
function prebook_start()
	TimerCrtl()		--�ر����ж�ʱ��
	TimerCrtl(0, 3000, true, prebook_run)	--ÿ��3s���һ���Ƿ�ʱ
	
	--������ʾ
	ModeState = 1	--����״̬
	DisFunc = 0		--������
	DisLed = 1000	--��ʼled����
	DisGL = 0	--���ֲ���
	DisGJ = 0	--���߲���
	DisMenu = ModeMenu + 100	--�˵�����
	DisHeng = DisMenu
	DisKG = DisKG % 10	--�ڸв���
	DisMZ = DisMZ % 10	--���ֲ���	
	DisTimeT = 11 --ԤԼʱ�䲻��	
end

--[[
������������ModeStateѡȡ��ͬ����
--]]
function keyEvent()
	--get key
	local key,lp = read(60)
	if key == 0 then return end
	
	--����+����(��ϰ���) ����������ر�
	if key == 0x35 then DisVoice = (DisVoice + 1) % 2 end

	--����״̬��ֻ��Ӧȡ������
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
		
	--���ܰ������ǹ���״̬��ѡ����һ���˵�
	if key == 0x02 and ModeState ~= 1 then  mode_select(ModeMenu+1) return end
	
	--����
	if key == 0x06 or (ModeState > 1 and key ~= 4 and key >= 3 and key <= 8) then return keySetting(key, lp) end
	
	if not lp then
		--ȡ��/����
		if key == 0x04 then
			if ModeState == 0 then 
				--���뱣��
				mode_select(10)
				mode_start()
			else
				mode_select(ModeMenu)	
			end
		elseif key == 0x01 then
			if ModeState == 2 then
				--ԤԼ��ʱ
				prebook_start()
			elseif ModeState == 5 then
				--�˳�ϵͳʱ������
				mode_select(ModeMenu)	
			else
				mode_start()
			end
		elseif key == 0x03 or key == 0x07 then 
			--����+
			mode_select(ModeMenu+1)
		elseif key == 0x05 or key == 0x08 then
			--����-
			mode_select(ModeMenu-1)
		elseif key == 0x31 then
			--������
			mode_select(1)
			mode_start()
		elseif key == 0x32 then
			--������
			mode_select(0)
			mode_start()
		elseif key == 0x34 then
			--����
			mode_select(2)
			mode_start()
		end		
	else
		--��������

	end 
end

--[[
������ʾ
--]]
function update_dis()
	--10ϵͳʱ�䣬11ԤԼʱ�䣬12����ʱ�䣬13ʣ��ʱ��,14����ʱ��
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
		--����ʱ�䣬����ʾ�˵�
		write(80, DisFunc, DisLed, 0, 0, 0,
			0, 0, 0, DisVoice, DisTimeT, DisTimeM)
	else
		--������ʾ
		write(80, DisFunc, DisLed, DisMenu, DisHeng, DisKG,
			DisMZ, DisGL, DisGJ, DisVoice, DisTimeT, DisTimeM)		
	end
end

-----------------------------------------------------------------------------------
--                                     main entry
-----------------------------------------------------------------------------------
do
	local sleepdev = 120 --���ߣ��ó�cpu
	local maintimer = 1
	local write = write
	local read = read
	write(0, 800)
	mode_select(1)
	mode_select(0)
	while true do
		--������ʱʱ��
		write(maintimer, 100)
	
		keyEvent()
		
		--��ʱ������
		TimerUpdate()
		
		--��������
		if ModeWorker and ModeState == 1 then 
			ModeWorker() 
		end
		
		--������ʾ
		update_dis()

		--����ʣ��ʱ��
		do
			local sleepMs = read(maintimer)
			--if true then ModeLeftT = 100 - sleepMs; update_dis(); end --���ԣ���ʾ����ʱ��
			if sleepMs <= 100 then write(sleepdev, sleepMs) end
		end
	end
end
