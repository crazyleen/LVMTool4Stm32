#-*- coding: utf-8 -*-

import sys
import LVMTool4Stm32 


if __name__ == '__main__':
	#redirect stdout
	consoleText = LVMTool4Stm32.textGUI.printTextGui(30,120)
	sys.stdout = consoleText
	
	src = ["main.lua"]
	target = "main"
	machine="diancilu00001"

	try:
		luacfile = target + ".luac"
		binfile = target + ".bin"
		tool = LVMTool4Stm32.compile.MediaCompile()
		tool.compile(src, luacfile)
		LVMTool4Stm32.compile.genbin.MediaScript().tobin(luacfile, binfile, machine)
		print("target file: %s" % binfile)
		LVMTool4Stm32.flash.flash_tool().flash(binfile, 0x08014800)
	except Exception, e:
		print e
		
		
	#show window
	consoleText.show()




