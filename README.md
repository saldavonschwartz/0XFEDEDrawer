# OXFEDEDrawer

Customizable drawer (`UIViewController` container) for iOS.


## How to use it:
1. Make sure you have both the `OXFEDEDrawer` `OXFEDEDrawerAppearanceDelegate` classes in your project.
2. Include `OXFEDEDrawer.h`
3. Look at the drawer public interface for a list of properties you can change at runtime.
	A simple example:

	```objc
		//	Inside some view controller:

	    self.drawer = [OXFEDEDrawer new];
	    self.drawer.container = self;
	    self.drawerContent = //	Some other view controller
	    self.drawer.content = self.drawerContent;
	```

4. For further customization inherit from the default appearance delegate `OXFEDEDrawerAppearanceDelegate` or implement the `OXFEDEDrawerAppearanceDelegate` protocol.


[Detailed tutorial on this component's implementation](http://0xfede.io/2015/12/06/T-iOS-Drawer.html)

<br>
Copyright (c) 2015 Federico Saldarini

[LinkedIn][l1] | [Blog][l2] | [GitHub][l3]

[l1]: https://www.linkedin.com/in/federicosaldarini
[l2]: http://0xfede.io
[l3]: https://github.com/saldavonschwartz
