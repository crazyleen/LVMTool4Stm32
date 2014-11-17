#-*- coding: utf-8 -*-

import sys
import LVMTool4Stm32 


if __name__ == '__main__':
	#redirect stdout
	consoleText = LVMTool4Stm32.textGUI.printTextGui(30,120)
	sys.stdout = consoleText
	
	try:
		LVMTool4Stm32.flash.flash_tool().eraseScript()
	except Exception, e:
		print e
		
		
	#show window
	consoleText.show()




