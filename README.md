# F3DEDrawer

Simple drawer (`UIViewController` container) for iOS. 


## How to use it:
1. Make sure you have both the `F3DEDrawer` `F3DEDrawerAppearanceDelegate` classes in your project. 
2. Include `F3DEDrawer.h` 
3. Look at the drawer public interface for a list of properties you can change at runtime. 
	A simple example:

	```	
		//	Inside some view controller:
		
	    self.drawer = [F3DEDrawer new];
	    self.drawer.container = self;
	    self.drawerContent = //	Some other view controller
	    self.drawer.content = self.drawerContent;
	```

4. For further customization inherit from the default appearance delegate `F3DEDrawerAppearanceDelegate` or implement the `F3DEDrawerAppearanceDelegate` protocol.


[Detailed tutorial on this component's implementation](www.apple.com)


Copyright (c) 2015 Federico Saldarini

https://www.linkedin.com/in/federicosaldarini

