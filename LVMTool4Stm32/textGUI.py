#-*- coding: utf-8 -*-
import Tkinter as Tk
import sys
import LVMTool4Stm32 

class printText(Tk.Text):
	def __init__(self, master=None, x=20, y=100):
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
	
	def show(self):
		self.config(state="disable")
		Tk.mainloop()

if __name__ == '__main__':
	#redirect stdout
	consoleText = printTextGui(30,120)
	sys.stdout = consoleText
	
	print("hello")
		
	#show window
	consoleText.show()