#-*- coding: utf-8 -*-
import Tkinter as Tk
import sys
import LVMTool4Stm32 
import ctypes

class printText(Tk.Text):
	def __init__(self, master=None, x=20, y=100, hideconsole=True):
		#hide console window
		if hideconsole:
			whnd = ctypes.windll.kernel32.GetConsoleWindow()
			if whnd != 0:
				ctypes.windll.user32.ShowWindow(whnd, 0)
				ctypes.windll.kernel32.CloseHandle(whnd)
		Tk.Text.__init__(self,height = x,width =y)
		self.scrollbar = Tk.Scrollbar(master)
		self.scrollbar.pack(side=Tk.RIGHT, fill=Tk.Y)
		self.pack()
		self.config(yscrollcommand=self.scrollbar.set)
		self.scrollbar.config(command=self.yview)

	def write(self, data):
		self.config(state="normal")
		self.insert(Tk.INSERT, data)
		self.config(state="disable")

class printTextGui(printText):
	
	def __init__(self, height, width):
		self.root = Tk.Tk()
		printText.__init__(self, master=self.root, x=height, y=width)
		#printText.__init__(self, master=self.root, x=height, y=width, hideconsole=False)
	
	def show(self):
		self.config(state="disable")
		Tk.mainloop()

if __name__ == '__main__':
	#redirect stdout
	consoleText = printTextGui(30,120)
	sys.stdout = consoleText
	
	try:
		LVMTool4Stm32.flash.flash_tool().eraseScript()
	except Exception, e:
		print e
		
		
	#show window
	consoleText.show()




