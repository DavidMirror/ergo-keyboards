package table;
import table.NumberColumn;
import type.GetSetOn;
import type.NumRange;

/**
 * ...
 * @author YellowAfterlife
 */
class IntColumn<T> extends NumberColumn<T, Int> {
	override public function parseFilterValue(val:String):Int {
		return NumberColumn.parseIntValue(val);
	}
}