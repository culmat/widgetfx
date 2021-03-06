/*
 * Generated by JavaFX Production Suite NetBeans plugin.
 * ArrowUI.fx
 *
 * Created on Thu Nov 12 17:51:12 PST 2009
 */
package rallywidget;

import java.lang.*;
import javafx.scene.Node;
import javafx.fxd.FXDNode;

public class ArrowUI extends FXDNode {
	
	override public var url = "{__DIR__}Arrow.fxz";
	
	public-read protected var activeTaskImageGroup: Node;
	public-read protected var activeTaskIndicator: Node;
	public-read protected var inactiveTaskIndicator: Node;
	
	override protected function contentLoaded() : Void {
		activeTaskImageGroup=getNode("activeTaskImageGroup");
		activeTaskIndicator=getNode("activeTaskIndicator");
		inactiveTaskIndicator=getNode("inactiveTaskIndicator");
	}
	
	/**
	 * Check if some element with given id exists and write 
	 * a warning if the element could not be found.
	 * The whole method can be removed if such warning is not required.
	 */
	protected override function getObject( id:String) : Object {
		var obj = super.getObject(id);
		if ( obj == null) {
			System.err.println("WARNING: Element with id {id} not found in {url}");
		}
		return obj;
	}
}

