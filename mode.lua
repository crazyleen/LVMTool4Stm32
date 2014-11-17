
-----------------------------------------------------------------------------------
--                                   �˵�
-----------------------------------------------------------------------------------
ModeSetting = nil	--�˵�����

ModeStep = 0	--�����׶�
ModeTNow = 0 	--��ǰϵͳʱ�䣬��
ModeTStart = 0	--��ʼ����ʱ��
ModeTStep = 0	--��ǰ�׶ο�ʼʱ��
ModeSecFlg = false	--ÿ��
ModeMinFlg = false 	--ÿ����

BotTem = 0	--�ײ��¶�
TopTem = 0	--�����¶�

HeatWater = false	--��ˮ���־
MenuWrong = false	--�ٴ��󷹱�־
ContinueCook = false 	--������

--����ʱ���룩���������24Сʱ
function deltaTime(now, pass)
	local delta = now - pass
	--����24Сʱ���ʱ��
	if delta < 0 then 
		delta = delta + 24*3600 
	end	
	return delta
end

function mode_flg_clear()
	HeatWater = false		--��ˮ���־
	MenuWrong = false		--�ٴ��󷹱�־
	ContinueCook = false 	--������
	TrouBleMode = false	
	MiShui = -2 			--��ˮ���� -2��δ��ʼ��⣬-1����У�>=0��ˮ��
end

--[[
�׶�1���
�ڵ�31sʱ����¶���������������־λ��
	MenuWrong 
	ContinueCook 
	HeatWater 
��������true����δ��������false
--]]
function mode_check()
--[[
1�����׶Σ���31��ʱ��
                    �ٵײ��¶��� >= 70�棬ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��λ��(���й���)
                    �����ϸ��¶� >= 48�棬�������־ContinueCook_F��λ��(���й���)
                    �����ײ��¶���31����������� 5 ��ADֵ����ˮ���־ HeatWater��λ��(���й���)
--]]
	local botTem,topTem = BotTem,TopTem
	
	--����ý׶ξ�����ʱ��
	local passtime = deltaTime(ModeTNow, ModeTStep)
	if passtime < 31 then 
		mode_check_flg = true
		botTemBak = 0
		MenuWrong = false
		ContinueCook = false
		HeatWater = false
	elseif passtime >= 31 and mode_check_flg then 
		mode_check_flg = false
		if botTem >= 70 then MenuWrong = true end	--ȡ�����ٰ���ʼ��
		if topTem >= 48 then ContinueCook = true end 	--������
		botTemBak = topTem	--���浱ǰֵ
	elseif passtime >= 32 then
		if botTem > botTemBak + 5 then HeatWater = true end	--��ˮ��
		--������һ���׶�
		return true
	end
	
	return false
end

--[[
��������
����Ĭ�ϵĿڸУ����֣�����ʱ��: mode_worker(true)	
����������mode_worker()
--]]
function mode_worker(init)
	if init then
		ModeStep = 0			--��ʼ�����
		return ModeSetting(0)	--���أ��ڸУ����֣�����ʱ��
	end
	
	local read = read
	local write = write
	
	--���µ�ǰʱ��
	local now = read(0)
	--�ײ��������¶�
	BotTem,TopTem = read(40)
	
	--��ʼ���׶�
	if ModeStep <= 0 then
		ModeStep = 1		--����׶�1
		ModeTNow = now		--���µ�ǰʱ��
		ModeTStep = now		--��¼�׶ο�ʼʱ��
		ModeSecFlg = false	--ÿ��
		ModeMinFlg = false 	--ÿ����
		ModeTStart = now	--��¼��ʼ����ʱ��
	end
	
	--���־
	if now ~= ModeTNow then ModeSecFlg = true; ModeTNow = now; else ModeSecFlg = false;	end
	--���ӱ�־
	if ModeSecFlg and (deltaTime(now, ModeTStart) % 60 == 0) then ModeMinFlg = true else ModeMinFlg = false	end

	--��ʱ������
	if ModeMinFlg then ModeLeftT = ModeLeftT - 1 end
	
	local run_again = true
	while run_again do
		run_again = false
		
		--step>0���أ�
		--	ʱ�䣬
		--	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
		--  ���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
		--	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
		--	�Ƿ�Ǩ��
		local timeout,botTemOver,botTemCtrl,botDuty,botCycle,
			sideTemOver,sideTemCtrl,sideDuty,sideCycle,
			topTemOver,topTemCtrl,topDuty,topCycle,
			nextstep = ModeSetting(ModeStep)
		
		--������һ�׶�������
		--	������Ƿ�Ǩ�ƣ���ִ���Ƿ�Ǩ�Ʒ���true
		--	��ʱ
		--	����Ǩ���¶�
		if (nextstep == true)
			or (timeout <= 0 or deltaTime(ModeTNow,ModeTStep) >= timeout)
			or (botTemOver > 0 and BotTem >= botTemOver)
			or (topTemOver > 0 and TopTem >= topTemOver) then  
			--�Ƿ�Ǩ�Ʒ���true���ʾ�׶�Ǩ��
			ModeStep = ModeStep + 1	--������һ�׶�
			ModeTStep = now 		--��¼�׶ο�ʼʱ��
			run_again = true		--����ִ���½׶�
		end
		
		--���ȿ���
		write(20, botTemCtrl, botDuty, botCycle)	--�ײ�
		write(21, sideTemCtrl, sideDuty, sideCycle)	--���
		write(22, topTemCtrl,topDuty,topCycle)		--����
	
		--������ɻ�ʱ��ľ������뱣��
		if ModeStep > 13 or ModeLeftT <= 0 then
			mode_select(10)
			mode_start()
			break	--��ģʽ����
		end
	
	end
end


--[[
������
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode0_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 1,1,43
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
������
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode1_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 1,1,25
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
����
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode2_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 0,1,60
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
ϡ��
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode3_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 0,1,30
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
Ӥ����
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode4_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 0,1,120
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
������
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode5_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 1,1,60
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
��˾��
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode6_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 1,1,60
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
����
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode7_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 0,0,30
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
����
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode8_setting(step)
	if step == 0 then	--��ʼ���׶�
		mode_flg_clear()
		return 0,0,120
	elseif step == 1 then	--�׶�1 check
		if ModeSecFlg then mode_check() end
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1

	elseif step == 3 then	--�׶�3 ��ˮ2
		--[[
		2����ˮ2�׶Σ������������־ContinueCook_F����ˮ���־ HeatWater_F����ˮ2Ǩ��ʱ���Ϊ5���ӣ�������Ϊ0��
		3����ˮ2�׶Σ�����ȡ���󷹺��ٰ���ʼ�󷹵ı�־MenuWrong_F����ˮ2Ǩ��ʱ���Ϊ0���ӣ�������Ϊ0��
		--]]
		if MenuWrong then
			return 0,130,0,0,0,0,0,0,0,130,0,0,0,true
		elseif ContinueCook or HeatWater then 
			return 5*60,130,0,0,0,0,0,0,0,130,0,0,0,false
		else
			return 18*60,130,50,12,16,0,0,0,0,130,0,0,0,false
		end
		
	elseif step == 4 then	--�׶�4 ����1	
		--4������1�׶Σ����ײ��¶� > 123��(BB)����������־TrouBleMode_F��λ����ʱ���ײ���120���¶ȿ��ơ�(���й���)
		local botTemCtrl = 122
		if BotTem > 123 then 
			TrouBleMode = true 
			botTemCtrl = 120
		end
		
		--5������1�׶Σ��ײ��¶� >= 60��(47) ��ʼ�ж���ˮ����ʱ��(���й��ܵ���ˮ���ȼ����������ж�)
		--			  ���ײ��¶� >= 90��(80) �� �ϸ��¶� >=85��(63) ͬʱ��ﵽʱ��������ˮ���жϡ�
		if MiShui == -2 and BotTem > 60 then 
			MiShui = -1			--��ˮ�����
			MiShuiT = ModeTNow	--��¼��ǰʱ��
		elseif MiShui == -1 and BotTem > 90 and TopTem > 85 then
			--[[
			ˮ�����ȼ�			0					1				2				3			
�ж�����	����1 ʱ�䣨ƫӲ��	< 120s				< 180s			< 360s			>= 360s			
			����1 ʱ�䣨ƫ��	< 120s				< 240s			< 360s			>= 360s			
			����1 ʱ�䣨���У�	< 120s				< 180s			< 360s			>= 360s			
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
		
		--6������1�׶Σ��жϳ���ˮ���󣬼���1������Ϊ 14/16����������
		local onduty = 16
		if MiShui >= 0 then
			onduty = 14
		end
		
		--17��������TrouBleMode_F��ˮ���ȼ�ǿ��Ϊ2�ȼ�����ˮ�� HeatWater_F��ȡ���󷹺��ٰ���ʼ��MunuWrong_F��������ContinueCook_F����ˮ���ȼ�ǿ��Ϊ3�ȼ���(���й���)
		if TrouBleMode then MiShui = 2 end
		if HeatWater or MenuWrong or ContinueCook then MiShui = 3 end
		
		return 30*60,148,botTemCtrl,onduty,16,0,0,0,0,95,0,0,0,false
		
	elseif step == 5 then	--�׶�5 ֹͣ1
		--7��ֹͣ1�׶Σ������ƽ���¶ȵ�Ǩ�ƣ�ֹͣ5���ӣ�������Ϊ2��
		if BotTem >= 148 or TopTem >= 95 then 
			return 5,0,0,2,16,0,0,0,0,0,0,0,0,false
		end
		return 5,0,0,0,0,0,0,0,0,0,0,0,0,false
		
	elseif step == 6 then	--�׶�6 ����2
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�6(����2)������			8					8				9				10			
		�׶�6(����2)�ײ�Ǩ���¶�	105�� 				105�� 			105�� 			110�� ( A5H )			
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
		
		--8������2�׶Σ����е�������־ TroubleMode_F���ϸ�Ǩ���¶ȸ�Ϊ 89��(6B)����ʱ������ײ����ϸ���һ������������һ�׶�Ǩ�ơ�(���й���)
		local topTemOver = 95
		if TrouBleMode then 
			topTemOver = 89
		end
		return 5*60,botTemOver,120,botDuty,16,0,0,0,0,topTemOver,0,0,0,false
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
		--[[
		��ˮ���ȼ�		0				1			2			3
		�׶�7(ֹͣ2)	1				1			1			2
		--]]
		local timeout = 1*60
		if MiShui == 3 then timeout = 2*60 end
		
		--9��ֹͣ2�׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 3���ӡ�(���й���)
		if TrouBleMode then timeout = 3*60 end
		
		return timeout,148,115,4,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 8 then	--�׶�8 ��������1
		local botTemOver,botDuty
		
		--[[
		��ˮ���ȼ�					0					1				2				3
		�׶�8(ά�ַ���1) ����		6					6				7				8			
		�׶�8(ά�ַ���1) �ײ�Ǩ��	108�� 				110��			115��			120�� 			
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
		
		--10������1�׶Σ��������־ContinueCook_F����ˮ���־ HeatWater_F��������Ϊ6��
		if ContinueCook or HeatWater then botDuty = 6 end
		
		--11������1�׶Σ������������־ ContinueCook_F �� ��������־ TroubleMode_F��ͬʱ�������� < 7��ͬ�����ȸ�Ϊ 7/16��
		if (ContinueCook or TrouBleMode) and botDuty < 7 then botDuty = 7 end
		
		--12������1�׶Σ���������ڽ׶ε�ʱ�� >= 900�룬�ײ�������Ϊ 9/16��
		if deltaTime(ModeTNow, ModeTStep) >= 900 then botDuty = 9 end
		
		return 30*60,botTemOver,0,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		--[[
		13���˷�ǰ�ȴ��׶Σ�������ˮ���־ HeatWater_F��ȡ���󷹺��ٰ���ʼ�󷹵ı�־MunuWrong_F��Ǩ��ʱ���Ϊ 2���ӡ�
		14���˷�ǰ�ȴ��׶Σ����е�������־ TroubleMode_F��Ǩ��ʱ���Ϊ 2���ӣ�������Ϊ5���ײ��¿�125�档
		--]]
		local timeout,botTem,botDuty = 0,0,0
		if HeatWater or MenuWrong then timeout = 2*60 end
		if TrouBleMode then 
			timeout = 2*60 
			botDuty = 5
			botTem = 125
		end
		return timeout,0,botTem,botDuty,16,0,0,0,0,0,0,0,0,false
		
	elseif step == 11 then	--�׶�11 ��1
		--15���˷��׶��жϣ���ˮ���ȼ� <=1 ʱ���˷���ʱ���Ϊ 8���ӣ�����ˮ���ȼ� >1�����˷�1��2��3�׶�Ǩ��ʱ��Ϊ���ʱ�䡣
		--16���˷�1�׶Σ�����ˮ���ȼ� >=3 ʱ��������Ϊ1/16��
		local timeout,botDuty = 5*60,1
		ModeLeftT = 8*60
		if MiShui <= 1 then 
			ModeLeftT = 8*60
		end 
		return timeout,160,110,botDuty,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 12 then	--�׶�11 ��2
		return 3*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	elseif step == 13 then	--�׶�11 ��3
		return 2*60,160,110,0,16,0,0,0,0,160,108,24,32,false
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end


--[[
�ȷ�
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode9_setting(step)
	local nextstep = false
		
	if step == 0 then	--��ʼ���׶�
		HeatWater = false	--��ˮ���־
		MenuWrong = false	--�ٴ��󷹱�־
		ContinueCook = false 	--������
		TrouBleMode = false	
		return 0,0,25
	elseif step == 1 then	--�׶�1 check
		return 32,130,0,0,0,130,0,0,0,130,0,0,0,false
	elseif step == 2 then	--�׶�2 ��ˮ1
	
	elseif step == 3 then	--�׶�3 ��ˮ2
		
	elseif step == 4 then	--�׶�4 ����1
		return 15*60,85,115,8,16,0,0,0,0,130,108,16,32,false
	elseif step == 5 then	--�׶�5 ֹͣ1
		
	elseif step == 6 then	--�׶�6 ����2
		
	elseif step == 7 then	--�׶�7 ֹͣ2
		
	elseif step == 8 then	--�׶�8 ��������1
		return 21*60,160,95,8,16,0,0,0,0,130,108,16,32,false
	elseif step == 9 then	--�׶�9 ��������2
		
	elseif step == 10 then	--�׶�10 ��ǰ�ȴ�
		
	elseif step == 11 then	--�׶�11 ��1
		return 2*60,130,95,4,16,0,0,0,0,130,108,16,32,false
	elseif step == 12 then	--�׶�11 ��2
		
	elseif step == 13 then	--�׶�11 ��3
		
	end	
	
	return 0,0,0,0,0,0,0,0,0,0,0,0,0,true
end

--[[
����
step==0���أ��ڸУ����֣���ʱ��
step >0���أ�
	ʱ�䣬
	�ײ�Ǩ���¶ȣ��ײ��¿أ��ײ�����ʱ�䣬�ײ��������ڣ�
	���Ǩ���¶ȣ�����¿أ���߼���ʱ�䣬��߼������ڣ�
	�ϸ�Ǩ���¶�,�ϸ��¿أ��ϸǼ���ʱ�䣬�ϸǼ������ڣ�
	�Ƿ�Ǩ��
--]]
function mode10_setting(step)
	if step == 0 then	--��ʼ���׶�
		ModeWarmT = 0
		return 0,0,3600
	end
	
	--ÿ���Ӹ���һ��
	if ModeMinFlg then
		ModeLeftT = 3600	--ˢ��ʣ��ʱ��
		ModeWarmT = deltaTime(ModeTNow, ModeTStart) / 60	--���㱣��ʱ��
	end
	
	local botTemOver,botTemCtrl,botDuty,botCycle,
		sideTemOver,sideTemCtrl,sideDuty,sideCycle,
		topTemOver,topTemCtrl,topDuty,topCycle
	
	local bottem = BotTem
	local toptem = TopTem
	if bottem >= 70 then 
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 0, 16		--�ײ����ȣ��¿�69��������0/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 2, 32	--��߼��ȣ��¿�69��������2/32
	elseif bottem >= 69 then
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 0, 16		--�ײ����ȣ��¿�69��������0/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 18, 32	--��߼��ȣ��¿�69��������18/32	
	elseif bottem >= 68 then
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 0, 16		--�ײ����ȣ��¿�69��������0/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 22, 32	--��߼��ȣ��¿�69��������22/32	
	elseif bottem >= 66 then
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 1, 16		--�ײ����ȣ��¿�69��������1/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 26, 32	--��߼��ȣ��¿�69��������26/32	
	else
		botTemOver,botTemCtrl,botDuty,botCycle = 1, 69, 2, 16		--�ײ����ȣ��¿�69��������2/16
		sideTemOver,sideTemCtrl,sideDuty,sideCycle = 1, 69, 30, 32	--��߼��ȣ��¿�69��������30/32	
	end
	
	if toptem > bottem + 0x14 then
		topTemOver,topTemCtrl,topDuty,topCycle = 1, 69, 2, 16		--�ϸǼ��ȣ��¿�69��������4/32
	else
		topTemOver,topTemCtrl,topDuty,topCycle = 1, 69, 30, 32		--�ϸǼ��ȣ��¿�69��������20/32
	end
	
	--25*3600=90000 ʱ�������ֻ��һ�죬�����ʾ�ò���ʱ
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