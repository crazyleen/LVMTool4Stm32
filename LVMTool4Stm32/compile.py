#-*- coding: utf-8 -*-

import os
import shutil
import fnmatch
import time
import genbin

class CompileError(Exception):
	def __init__(self, msg):
		self.x = msg
	
	def __str__(self):
		return self.x
		
class MediaCompile(object):
	def runCMD(self, cmd):
		ccoutput = os.popen3(cmd)
		message = ccoutput[1].read()
		if len(message) > 0:
			print message	
		message = ccoutput[2].read()
		if len(message) > 0:	
			raise CompileError(message)
			
	def combineFiles(self, sources, tempfile):
		with open(tempfile, "w") as dest:
			mainfile = "main.lua"
			for filename in sources:
				if filename == mainfile:
					continue
				print(filename)
				dest.write("--" + "#"*100 + '\n')
				dest.write("--" + " "*50 + filename + '\n')
				dest.write("--" + "#"*100 + '\n')
				self.runCMD("luac -s %s" %(filename))
				with open(filename) as src:
					shutil.copyfileobj(src, dest)
			print(mainfile)
			dest.write("--" + "#"*100 + '\n')
			dest.write("--" + " "*50 + mainfile + '\n')
			dest.write("--" + "#"*100 + '\n')
			
			self.runCMD("luac -s %s" %(mainfile))
			with open(mainfile) as src:
				shutil.copyfileobj(src, dest)	

	def compile(self, sources, binfile):
		tmpfile = binfile + ".tmp"
		try:
			self.combineFiles(sources, tmpfile)
			print("###compile --> %s" %(binfile))	
		finally:
			os.remove("luac.out")
			
		self.runCMD("luac -s -o %s %s" %(binfile, tmpfile))
		
if __name__ == '__main__':
	src = ["main.lua", "timer.lua", "mode.lua"]
	target = "main"
	machine="diancilu00001"

	try:
		luacfile = target + ".luac"
		tool = MediaCompile()
		tool.compile(src, luacfile)

		genbin.MediaScript().tobin(luacfile, target+".bin", machine)
	except IOError, e:
		print e

	#os.remove(tmpfile)
	time.sleep(5)