
import sys
import os

class flash_tool(object):
	"""
	use ST-LINK_CLI.exe to download program and reset
	"""
	
	command = r'C:"\Program Files\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\"ST-LINK_CLI.exe'
	
	def flash(self, programfile, address):
		output = os.popen3("%s  -V \"after_programming\" -P %s %d -Rst" % (self.command, programfile, address))
		print output[1].read()
		print output[2].read()

	def eraseScript(self):
		"erase user script"
		output = os.popen3("%s  -SE 40 63 -Rst" % (self.command))
		print output[1].read()
		print output[2].read()
		
if __name__ == "__main__":
	
	flash_tool().flash("main.bin", 0x08014800)