#-*- coding: utf-8 -*-
import sys
import LVMTool4Stm32 

if __name__ == '__main__':
	#redirect stdout
	consoleText = LVMTool4Stm32.textGUI.printTextGui(30,120)
	sys.stdout = consoleText
	
	binfile = "user.bin"
	
	try:
		LVMTool4Stm32.flash.flash_tool().flash(binfile, 0x08014000)
	except Exception, e:
		print e
		
		
	#show window
	consoleText.show()




