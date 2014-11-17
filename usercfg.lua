
------------------------------------------------------------------------------------
--                                 �û�ģʽ
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
�û�����ģʽ
����ֵ��ʱ��s,Ǩ���¶�,����,����,��ʾ����,ʵ�ʹ���,�����ڼ���ʱ��s,��������s,��������,��ʱ��min
STime,Temp,LTemp,HTemp,DisPow,ActPow,Duty,Cycle,Htype,TotalTime = setting_usercfg(Mstep)
--]]
function setting_usercfg(step)
	local heat_type = 1 --��������
	local totaltime = 60 --��ʱ��min
	local func,argc,argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9
	while true do
		func,argc,argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9 = read(888,step)
		if not func then return 0,0,0,0,0,0 end	--���һ��
		if func == 20015 then
				--����
				userfunc_alarm(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
				step = step + 1
				Mstep = step
		elseif func == 2014 then
			--�ػ�
			poweroff()
			return
		else
			func = setting_userfunc(func)
			if not func then return end	--û�ж�Ӧ���� 
			break
		end
	end

	local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)

	actPow = setting_userpow(actPow)
	
	return stime,temp,ltemp,htemp,actPow,actPow,20,20,heat_type,totaltime
end

--[[
�û����ú�������
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
�û����ú��������ȵ�ĳ���¶�

2)	���ȵ�ĳ���¶�
���趨�Ĺ��ʼ��ȵ�ĳ���¶ȣ��¶ȵ���ʱ�Զ�������һ������
�ӿڱ���Ϊ20012����2������������Ϊ�¶ȣ����ʡ�
local func,argc,argv0,argv1 = 20012,2,temp,power

���أ�ʱ�䣬Ǩ���¶ȣ����£����£�����
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_heat_temp(temp,power)
	return 3600,temp,0,0,power
end

--[[
�û����ú���������һ��ʱ��

1)	����һ��ʱ��
���趨�Ĺ��ʳ�������һ��ʱ��, ʱ������ʱ�Զ�������һ������
�ӿڱ���Ϊ20011����2������������Ϊʱ�䣬���ʡ�
local func,argc,argv0,argv1 = 20011,2,time,power

���أ�ʱ�䣬Ǩ���¶ȣ����£����£�����
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_heat(stime,power)
	return stime*60,500,0,0,power
end

--[[
�û����ú��������¼���

3)	���¼���
���趨�Ĺ��ʶ�����ĳ���¶ȣ�ʱ������ʱ�Զ�������һ�����衣
�ӿڱ���Ϊ20013����3������������Ϊʱ�䣬�¶ȣ����ʡ�
local func,argc,argv0,argv1,argv2 = 20013,3,time,temp,power

���أ�ʱ�䣬Ǩ���¶ȣ����£����£�����
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_keep(stime,temp,power)
	--��ȡ��Ϣ
	local device_temp = read(20)
	
	if device_temp > temp then 				--�¶ȹ���
		return stime*60,500,0,0,0,0			--ֹͣ����
	else
		return stime*60,500,0,0,power	--���¿�ʼ����
	end
end

--[[
1.	����������
local func,argc,argv0,argv1 = 20015, 2, 1, 0
2.	�ֻ�����
local func,argc,argv0,argv1 = 20015, 2, 0, 1

���أ�ʱ�䣬Ǩ���¶ȣ����£����£�����
local stime,temp,ltemp,htemp,actPow = func(argv0,argv1,argv2,argv3,argv4,argv5,argv6,argv7,argv8,argv9)
--]]
function userfunc_alarm(argv0,argv1)
	if argv0 == 1 and argv1 == 0 then
		write(70, 0)	--����������
	elseif argv0 == 0 and argv1 == 1 then
		write(70, 0)	--�ֻ�����
	end
	
	--Ϊ����ʱ500ms
	write(120, 500)
	
	return 0,0,0,0,0
end






