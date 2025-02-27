package table;
import type.Keyboard;
import type.*;
import js.html.Element;
using tools.HtmlTools;
import js.Browser.document;

/**
 * ...
 * @author YellowAfterlife
 */
class TagListColumn<KB:Keyboard, ET:EnumValue> extends TagColumnBase<KB, ET, ValList<ET>> {
	public var defaultValue:ValList<ET> = null;
	public var onBuildValue:(out:Element, vals:ValList<ET>, kb:KB)->Bool;
	public function new(name:String, field:FancyField<KB, ValList<ET>>, et:Enum<ET>) {
		super(name, field, et);
		defaultValue = et.createByIndex(0);
		this.field = field;
		this.type = et;
	}
	function getValue(kb:KB) {
		return field.access(kb) ?? defaultValue;
	}
	override public function buildValue(out:Element, kb:KB):Void {
		var vals = getValue(kb);
		if (vals != null) {
			var tip = [
				kb.name,// + " ➜ " +
				name + ":",
			];
			var addElements = true;
			if (onBuildValue != null && onBuildValue(out, vals, kb)) {
				addElements = false;
			}
			for (i => val in vals) {
				if (i > 0 && addElements) out.appendTextNode(", ");
				var name = val.getName();
				if (addElements) {
					out.appendTextNode(shortLabels[val] ?? name);
				}
				tip.push("· " + (filterLabels[val] ?? name));
			}
			out.title = tip.join("\n");
		} else {
			out.appendTextNode(nullCaption);
		}
	}
	
	public var usedValues:Map<ET, Bool> = new Map();
	override public function showInFilters(val:ET):Bool {
		return usedValues.exists(val);
	}
	override public function buildFilter(out:Element):Void {
		for (item in table.values) {
			var vals = getValue(item);
			if (vals == null) continue;
			for (val in vals) {
				if (!usedValues.exists(val)) usedValues[val] = true;
			}
		}
		super.buildFilter(out);
	}
	
	public function tagsContain(tags:Array<ET>, tag:ET) {
		return tags.contains(tag);
	}
	override public function matchesFilter(kb:KB):Bool {
		if (filterTags.length == 0) return true;
		var vals = getValue(kb);
		if (vals == null) {
			vals = defaultValue;
			if (vals == null) vals = [];
		}
		switch (filterMode) {
			case AnyOf:
				for (val in filterTags) {
					if (tagsContain(vals, val)) return true;
				}
				return false;
			case AllOf:
				for (val in filterTags) {
					if (!tagsContain(vals, val)) return false;
				}
				return true;
			case NoneOf:
				for (val in filterTags) {
					if (tagsContain(vals, val)) return false;
				}
				return true;
		}
	}
	
	override public function getVisibleTagNamesForLegends():Array<String> {
		var visible = new Map();
		var arr = [];
		for (row in table.rows) if (row.show) {
			var vals = getValue(row.value);
			if (vals == null) continue;
			for (val in vals) if (!visible.exists(val)) {
				visible[val] = true;
				arr.push(tagToName(val));
			}
		}
		return arr;
	}
	
	override public function buildEditor(out:Element, store:Array<KB->Void>, restore:Array<KB->Void>):Void {
		var optCtr = out.appendElTextNode("div");
		optCtr.classList.add("tag-options");
		optCtr.setAttribute("column-count", "" + columnCount);
		for (ctr in Type.getEnumConstructs(type)) {
			var val:ET = Type.createEnum(type, ctr);
			if (!showInEditor(val)) continue;
			var name = filterLabels[val] ?? ctr;
			
			var cb = document.createCheckboxElement();
			store.push(function(kb) {
				if (!cb.checked) return;
				var arr = field.access(kb);
				if (arr == null) {
					arr = [];
					field.access(kb, true, arr);
				}
				arr.push(val);
			});
			restore.push(function(kb) {
				var arr = field.access(kb);
				cb.checked = arr != null && arr.contains(val);
			});
			var label = document.createLabelElement();
			var row = document.createDivElement();
			label.appendChild(cb);
			label.appendTextNode(name);
			row.appendChild(label);
			optCtr.appendChild(row);
		}
	}
	
	override public function save(kb:KB):Void {
		var arr = field.access(kb);
		if (arr != null) {
			var names = arr.map(e -> e.getName());
			if (names.length == 1) {
				names = cast names[0];
			}
			field.access(kb, true, cast names);
		}
	}
	override public function load(kb:KB):Void {
		var names = field.access(kb);
		if (names != null) {
			if (!(names is Array)) names = cast [names];
			var arr = [];
			for (name in names) {
				if (name is Bool) {
					name = cast ((cast name:Bool) ? "Yes" : "No");
				}
				arr.push(type.createByName(cast name));
			}
			field.access(kb, true, arr);
		}
	}
}