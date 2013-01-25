/**
 * VERSION: 12.0.0
 * DATE: 2013-01-21
 * AS2 (AS3 version is also available)
 * UPDATES AND DOCS AT: http://www.greensock.com/timelinelite/
 **/
import com.greensock.TweenLite;
import com.greensock.core.SimpleTimeline;
import com.greensock.core.Animation;
/**
 * TimelineLite is a lightweight, intuitive timeline class for building and managing sequences of 
 * TweenLite, TweenMax, TimelineLite, and/or TimelineMax instances. 
 * 
 * <p><strong>See AS3 files for full ASDocs</strong></p>
 * 
 * <p><strong>Copyright 2008-2013, GreenSock. All rights reserved.</strong> This work is subject to the terms in <a href="http://www.greensock.com/terms_of_use.html">http://www.greensock.com/terms_of_use.html</a> or for <a href="http://www.greensock.com/club/">Club GreenSock</a> members, the software agreement that was issued with the membership.</p>
 * 
 * @author Jack Doyle, jack@greensock.com
 */
class com.greensock.TimelineLite extends SimpleTimeline {
		public static var version:String = "12.0.0";
		private static var _paramProps:Array = ["onStartParams","onUpdateParams","onCompleteParams","onReverseCompleteParams","onRepeatParams"];
		private var _labels:Object;
		
		public function TimelineLite(vars:Object) {
			super(vars);
			_labels = {};
			autoRemoveChildren = (this.vars.autoRemoveChildren == true);
			smoothChildTiming = (this.vars.smoothChildTiming == true);
			_sortChildren = true;
			_onUpdate = this.vars.onUpdate;
			var i:Number = _paramProps.length,
				j:Number, a:Array;
			while (--i > -1) {
				if ((a = this.vars[_paramProps[i]])) {
					j = a.length;
					while (--j > -1) {
						if (a[j] === "{self}") {
							a = this.vars[_paramProps[i]] = a.concat(); //copy the array in case the user referenced the same array in multiple timelines/tweens (each {self} should be unique)
							a[j] = this;
						}
					}
				}
			}
			if (this.vars.tweens instanceof Array) {
				this.add(this.vars.tweens, 0, this.vars.align || "normal", this.vars.stagger || 0);
			}
		}

		
//---- CONVENIENCE METHODS START --------------------------------------
		
		public function to(target:Object, duration:Number, vars:Object, position) {
			return add( new TweenLite(target, duration, vars), position); 
		}
		
		public function from(target:Object, duration:Number, vars:Object, position) {
			return add( TweenLite.from(target, duration, vars), position);
		}
		
		public function fromTo(target:Object, duration:Number, fromVars:Object, toVars:Object, position) {
			return add( TweenLite.fromTo(target, duration, fromVars, toVars), position);
		}
		
		public function staggerTo(targets:Array, duration:Number, vars:Object, stagger:Number, position, onCompleteAll:Function, onCompleteAllParams:Array, onCompleteAllScope:Object) {
			var tl:TimelineLite = new TimelineLite({onComplete:onCompleteAll, onCompleteParams:onCompleteAllParams, onCompleteScope:onCompleteAllScope});
			stagger = stagger || 0;
			for (var i:Number = 0; i < targets.length; i++) {
				if (vars.startAt != null) {
					vars.startAt = _copy(vars.startAt);
				}
				tl.add( new TweenLite(targets[i], duration, _copy(vars)), i * stagger);
			}
			return add(tl, position);
		}
		
		public function staggerFrom(targets:Array, duration:Number, vars:Object, stagger:Number, position, onCompleteAll:Function, onCompleteAllParams:Array, onCompleteAllScope:Object) {
			if (vars.immediateRender == null) {
				vars.immediateRender = true;
			}
			vars.runBackwards = true;
			return staggerTo(targets, duration, vars, stagger, position, onCompleteAll, onCompleteAllParams, onCompleteAllScope);
		}
		
		public function staggerFromTo(targets:Array, duration:Number, fromVars:Object, toVars:Object, stagger:Number, position, onCompleteAll:Function, onCompleteAllParams:Array, onCompleteAllScope:Object) {
			toVars.startAt = fromVars;
			if (fromVars.immediateRender) {
				toVars.immediateRender = true;
			}
			return staggerTo(targets, duration, toVars, stagger, position, onCompleteAll, onCompleteAllParams, onCompleteAllScope);
		}
		
		public function call(callback:Function, params:Array, scope:Object, position) {
			return add( TweenLite.delayedCall(0, callback, params, scope), position);
		}
		
		public function set(target:Object, vars:Object, position) {
			vars.immediateRender = false;
			return add( new TweenLite(target, 0, vars), position);
		}
		
		private static function _copy(vars:Object):Object {
			var copy:Object = {}, p:String;
			for (p in vars) {
				copy[p] = vars[p];
			}
			return copy;
		}
		
		public static function exportRoot(vars:Object, ignoreDelayedCalls:Boolean):TimelineLite {
			vars = vars || {};
			if (vars.smoothChildTiming == null) {
				vars.smoothChildTiming = true;
			}
			var tl:TimelineLite = new TimelineLite(vars),
				root:SimpleTimeline = tl._timeline;
			if (ignoreDelayedCalls == null) {
				ignoreDelayedCalls = true;
			}
			root._remove(tl, true);
			tl._startTime = 0;
			tl._rawPrevTime = tl._time = tl._totalTime = root._time;
			var tween:Animation = root._first, next:Animation;
			while (tween) {
				next = tween._next;
				if (!ignoreDelayedCalls || !(tween instanceof TweenLite && TweenLite(tween).target == tween.vars.onComplete)) {
					tl.add(tween, tween._startTime - tween._delay);
				}
				tween = next;
			}
			root.add(tl, 0);
			return tl;
		}
		
//---- CONVENIENCE METHODS END ----------------------------------------
		
		public function add(value, position, align:String, stagger:Number) {
			if (typeof(position) !== "number") {
				position = _parseTimeOrLabel(position, 0, true, value);
			}
			if (value instanceof Animation) {
				//continue...
			} else if (value instanceof Array) {
				align = align || "normal";
				stagger = stagger || 0;
				var i:Number, 
				curTime:Number = Number(position), 
					l:Number = value.length, 
					child;
				for (i = 0; i < l; i++) {
					if ((child = value[i]) instanceof Array) {
						child = new TimelineLite({tweens:child});
					}
					add(child, curTime);
					if (typeof(child) === "string" || typeof(child) === "function") {
						//do nothing
					} else if (align === "sequence") {
						curTime = child._startTime + (child.totalDuration() / child._timeScale);
					} else if (align === "start") {
						child._startTime -= child.delay();
					}
					curTime += stagger;
				}
				return _uncache(true);
			} else if (typeof(value) === "string") {
				return addLabel(String(value), position);
			} else if (typeof(value) === "function") {
				value = TweenLite.delayedCall(0, value);
			} else {
				trace("Cannot add " + value + " into the TimelineLite/Max: it is neither a tween, timeline, function, nor a String.");
				return this;
			}
			
			super.add(value, position);
			
			//if the timeline has already ended but the inserted tween/timeline extends the duration, we should enable this timeline again so that it renders properly.  
			if (_gc) if (!_paused) if (_time === _duration) if (_time < duration()) {
				//in case any of the anscestors had completed but should now be enabled...
				var tl:SimpleTimeline = this;
				while (tl._gc && tl._timeline) {
					if (tl._timeline.smoothChildTiming) {
						tl.totalTime(tl._totalTime, true); //also enables them
					} else {
						tl._enabled(true, false);
					}
					tl = tl._timeline;
				}
			}
			return this;
		}
		
		public function remove(value) {
			if (value instanceof Animation) {
				return _remove(value, false);
			} else if (value instanceof Array) {
				var i:Number = value.length;
				while (--i > -1) {
					remove(value[i]);
				}
				return this;
			} else if (typeof(value) == "string") {
				return removeLabel(String(value));
			}
			return kill(null, value);
		}
		
		public function append(value, offsetOrLabel) {
			return add(value, _parseTimeOrLabel(null, offsetOrLabel, true, value));
		}
		
		public function insertMultiple(tweens:Array, timeOrLabel, align:String, stagger:Number) {
			return add(tweens, timeOrLabel || 0, align, stagger);
		}
		
		public function appendMultiple(tweens:Array, offsetOrLabel, align:String, stagger:Number) {
			return add(tweens, _parseTimeOrLabel(null, offsetOrLabel, true, tweens), align, stagger);
		}
		
		public function addLabel(label:String, position) {
			_labels[label] = _parseTimeOrLabel(position);
			return this;
		}
	
		public function removeLabel(label:String) {
			delete _labels[label];
			return this;
		}
		
		public function getLabelTime(label:String):Number {
			return (_labels[label] != null) ? _labels[label] : -1;
		}
		
		private function _parseTimeOrLabel(timeOrLabel, offsetOrLabel, appendIfAbsent:Boolean, ignore:Object):Number {
			var i:Number;
			//if we're about to add a tween/timeline (or an array of them) that's already a child of this timeline, we should remove it first so that it doesn't contaminate the duration().
			if (ignore instanceof Animation && ignore.timeline === this) {
				remove(ignore);
			} else if (ignore instanceof Array) {
				i = ignore.length;
				while (--i > -1) {
					if (ignore[i] instanceof Animation && ignore[i].timeline === this) {
						remove(ignore[i]);
					}
				}
			}
			if (typeof(offsetOrLabel) === "string") {
				return _parseTimeOrLabel(offsetOrLabel, (appendIfAbsent && typeof(timeOrLabel) === "number" && _labels[offsetOrLabel] == null) ? timeOrLabel - duration() : 0, appendIfAbsent);
			}
			offsetOrLabel = offsetOrLabel || 0;
			if (typeof(timeOrLabel) === "string" && (isNaN(timeOrLabel) || _labels[timeOrLabel] != null)) { //if the string is a number like "1", check to see if there's a label with that name, otherwise interpret it as a number (absolute value).
				i = timeOrLabel.indexOf("=");
				if (i === -1) {
					if (_labels[timeOrLabel] == null) {
						return appendIfAbsent ? (_labels[timeOrLabel] = duration() + offsetOrLabel) : offsetOrLabel;
					}
					return _labels[timeOrLabel] + offsetOrLabel;
				}
				offsetOrLabel = parseInt(timeOrLabel.charAt(i-1) + "1", 10) * Number(timeOrLabel.substr(i+1));
				timeOrLabel = (i > 1) ? _parseTimeOrLabel(timeOrLabel.substr(0, i-1), 0, appendIfAbsent) : duration();
			} else if (timeOrLabel == null) {
				timeOrLabel = duration();
			}
			return Number(timeOrLabel) + offsetOrLabel;
		}
		
		public function seek(position, suppressEvents:Boolean) {
			return totalTime((typeof(position) === "number") ? Number(position) : _parseTimeOrLabel(position), (suppressEvents != false));
		}
		
		public function stop() {
			return paused(true);
		}
	
		public function gotoAndPlay(position, suppressEvents:Boolean) {
			return super.play(position, suppressEvents);
		}
		
		public function gotoAndStop(position, suppressEvents:Boolean) {
			return pause(position, suppressEvents);
		}
		
		public function render(time:Number, suppressEvents:Boolean, force:Boolean):Void {
			if (_gc) {
				_enabled(true, false);
			}
			_active = !_paused; 
			var totalDur:Number = (!_dirty) ? _totalDuration : totalDuration(), 
				prevTime:Number = _time, 
				prevStart:Number = _startTime, 
				prevTimeScale:Number = _timeScale, 
				prevPaused:Boolean = _paused,
				tween:Animation, isComplete:Boolean, next:Animation, callback:String;
			if (time >= totalDur) {
				_totalTime = _time = totalDur;
				if (!_reversed) if (!_hasPausedChild()) {
					isComplete = true;
					callback = "onComplete";
					if (_duration === 0) if (time === 0 || _rawPrevTime < 0) if (_rawPrevTime !== time) { //In order to accommodate zero-duration timelines, we must discern the momentum/direction of time in order to render values properly when the "playhead" goes past 0 in the forward direction or lands directly on it, and also when it moves past it in the backward direction (from a postitive time to a negative time).
						force = true;
					}
				}
				_rawPrevTime = time;
				time = totalDur + 0.000001; //to avoid occassional floating point rounding errors in Flash - sometimes child tweens/timelines were not being fully completed (their progress might be 0.999999999999998 instead of 1 because when Flash performed _time - tween._startTime, floating point errors would return a value that was SLIGHTLY off)

			} else if (time <= 0) {
				_totalTime = _time = 0;
				if (prevTime != 0 || (_duration == 0 && _rawPrevTime > 0)) {
					callback = "onReverseComplete";
					isComplete = _reversed;
				}
				if (time < 0) {
					_active = false;
					if (_duration == 0) if (_rawPrevTime >= 0) { //zero-duration timelines are tricky because we must discern the momentum/direction of time in order to determine whether the starting values should be rendered or the ending values. If the "playhead" of its timeline goes past the zero-duration tween in the forward direction or lands directly on it, the end values should be rendered, but if the timeline's "playhead" moves past it in the backward direction (from a postitive time to a negative time), the starting values must be rendered.
						force = true;
					}
				} else if (!_initted) {
					force = true;
				}
				_rawPrevTime = time;
				time = -0.000001; //to avoid occassional floating point rounding errors in Flash - sometimes child tweens/timelines were not being rendered at the very beginning (their progress might be 0.000000000001 instead of 0 because when Flash performed _time - tween._startTime, floating point errors would return a value that was SLIGHTLY off)
				
			} else {
				_totalTime = _time = _rawPrevTime = time;
			}
			
			if (_time === prevTime && !force) {
				return;
			} else if (!_initted) {
				_initted = true;
			}
			if (prevTime === 0) if (vars.onStart) if (_time !== 0) if (!suppressEvents) {
				vars.onStart.apply(vars.onStartScope || this, vars.onStartParams);
			}
			
			if (_time > prevTime) {
				tween = _first;
				while (tween) {
					next = tween._next; //record it here because the value could change after rendering...
					if (_paused && !prevPaused) { //in case a tween pauses the timeline when rendering
						break;
					} else if (tween._active || (tween._startTime <= _time && !tween._paused && !tween._gc)) {
						
						if (!tween._reversed) {
							tween.render((time - tween._startTime) * tween._timeScale, suppressEvents, false);
						} else {
							tween.render(((!tween._dirty) ? tween._totalDuration : tween.totalDuration()) - ((time - tween._startTime) * tween._timeScale), suppressEvents, false);
						}
						
					}
					tween = next;
				}
			} else {
				tween = _last;
				while (tween) {
					next = tween._prev; //record it here because the value could change after rendering...
					if (_paused && !prevPaused) { //in case a tween pauses the timeline when rendering
						break;
					} else if (tween._active || (tween._startTime <= prevTime && !tween._paused && !tween._gc)) {
						
						if (!tween._reversed) {
							tween.render((time - tween._startTime) * tween._timeScale, suppressEvents, false);
						} else {
							tween.render(((!tween._dirty) ? tween._totalDuration : tween.totalDuration()) - ((time - tween._startTime) * tween._timeScale), suppressEvents, false);
						}
						
					}
					tween = next;
				}
			}
			
			if (_onUpdate != null) if (!suppressEvents) {
				_onUpdate.apply(vars.onUpdateScope || this, vars.onUpdateParams);
			}
			
			if (callback) if (!_gc) if (prevStart === _startTime || prevTimeScale != _timeScale) if (_time === 0 || totalDur >= totalDuration()) { //if one of the tweens that was rendered altered this timeline's startTime (like if an onComplete reversed the timeline), it probably isn't complete. If it is, don't worry, because whatever call altered the startTime would complete if it was necessary at the new time. The only exception is the timeScale property. Also check _gc because there's a chance that kill() could be called in an onUpdate
				if (isComplete) {
					if (_timeline.autoRemoveChildren) {
						_enabled(false, false);
					}
					_active = false;
				}
				if (!suppressEvents) if (vars[callback]) {
					vars[callback].apply(vars[callback + "Scope"] || this, vars[callback + "Params"]);
				}
			}
			
		}
		
		public function _hasPausedChild():Boolean {
			var tween:Animation = _first;
			while (tween) {
				if (tween._paused || ((tween instanceof TimelineLite) && TimelineLite(tween)._hasPausedChild())) {
					return true;
				}
				tween = tween._next;
			}
			return false;
		}
		
		public function getChildren(nested:Boolean, tweens:Boolean, timelines:Boolean, ignoreBeforeTime:Number):Array {
			ignoreBeforeTime = ignoreBeforeTime || -9999999999;
			var a:Array = [], 
				tween:Animation = _first, 
				cnt:Number = 0;
			while (tween) {
				if (tween._startTime < ignoreBeforeTime) {
					//do nothing
				} else if (tween instanceof TweenLite) {
					if (tweens != false) {
						a[cnt++] = tween;
					}
				} else {
					if (timelines != false) {
						a[cnt++] = tween;
					}
					if (nested != false) {
						a = a.concat(TimelineLite(tween).getChildren(true, tweens, timelines));
						cnt = a.length;
					}
				}
				tween = tween._next;
			}
			return a;
		}
		
		public function getTweensOf(target:Object, nested:Boolean):Array {
			var tweens:Array = TweenLite.getTweensOf(target), 
				i:Number = tweens.length, 
				a:Array = [], 
				cnt:Number = 0;
			while (--i > -1) {
				if (tweens[i].timeline == this || (nested && _contains(tweens[i]))) {
					a[cnt++] = tweens[i];
				}
			}
			return a;
		}
		
		private function _contains(tween:Animation):Boolean {
			var tl:SimpleTimeline = tween.timeline;
			while (tl) {
				if (tl === this) {
					return true;
				}
				tl = tl.timeline;
			}
			return false;
		}
		
		public function shiftChildren(amount:Number, adjustLabels:Boolean, ignoreBeforeTime:Number) {
			ignoreBeforeTime = ignoreBeforeTime || 0;
			var tween:Animation = _first;
			while (tween) {
				if (tween._startTime >= ignoreBeforeTime) {
					tween._startTime += amount;
				}
				tween = tween._next;
			}
			if (adjustLabels) {
				for (var p:String in _labels) {
					if (_labels[p] >= ignoreBeforeTime) {
						_labels[p] += amount;
					}
				}
			}
			return _uncache(true);
		}
		
		public function _kill(vars:Object, target:Object):Boolean {
			if (vars == null) if (target == null) {
				return _enabled(false, false);
			}
			var tweens:Array = (target == null) ? getChildren(true, true, false) : getTweensOf(target),
				i:Number = tweens.length, 
				changed:Boolean = false;
			while (--i > -1) {
				if (tweens[i]._kill(vars, target)) {
					changed = true;
				}
			}
			return changed;
		}
		
		public function clear(labels:Boolean) {
			var tweens:Array = getChildren(false, true, true),
				i:Number = tweens.length;
			_time = _totalTime = 0;
			while (--i > -1) {
				tweens[i]._enabled(false, false);
			}
			if (labels != false) {
				_labels = {};
			}
			return _uncache(true);
		}
		
		public function invalidate() {
			var tween:Animation = _first;
			while (tween) {
				tween.invalidate();
				tween = tween._next;
			}
			return this;
		}
		
		public function _enabled(enabled:Boolean, ignoreTimeline:Boolean):Boolean {
			if (enabled == _gc) {
				var tween:Animation = _first;
				while (tween) {
					tween._enabled(enabled, true);
					tween = tween._next;
				}
			}
			return super._enabled(enabled, ignoreTimeline);
		}
		
		
		
//---- GETTERS / SETTERS -------------------------------------------------------------------------------------------------------
		
		public function progress(value:Number) {
			return (!arguments.length) ? _time / duration() : totalTime(duration() * value, false);
		}
		
		public function duration(value:Number) {
			if (!arguments.length) {
				if (_dirty) {
					totalDuration(); //just triggers recalculation
				}
				return _duration;
			}
			if (duration() !== 0) if (value !== 0) {
				timeScale(_duration / value);
			}
			return this;
		}
		
		public function totalDuration(value:Number) {
			if (!arguments.length) {
				if (_dirty) {
					var max:Number = 0, 
						tween:Animation = _first, 
						prevStart:Number = -999999999999, 
						next:Animation, end:Number;
					while (tween) {
						next = tween._next; //record it here in case the tween changes position in the sequence...
						
						if (tween._startTime < prevStart && _sortChildren) { //in case one of the tweens shifted out of order, it needs to be re-inserted into the correct position in the sequence
							add(tween, tween._startTime - tween._delay);
						} else {
							prevStart = tween._startTime;
						}
						if (tween._startTime < 0) {//children aren't allowed to have negative startTimes, so adjust here if one is found.
							max -= tween._startTime;
							shiftChildren(-tween._startTime, false, -9999999999);
						}
						end = tween._startTime + ((!tween._dirty ? tween._totalDuration : tween.totalDuration()) / tween._timeScale);
						if (end > max) {
							max = end;
						}
						
						tween = next;
					}
					_duration = _totalDuration = max;
					_dirty = false;
				}
				return _totalDuration;
			}
			if (totalDuration() !== 0) if (value !== 0) {
				timeScale(_totalDuration / value);
			}
			return this;
		}
		
		public function usesFrames():Boolean {
			var tl:SimpleTimeline = _timeline;
			while (tl._timeline) {
				tl = tl._timeline;
			}
			return (tl === _rootFramesTimeline);
		}
		
		public function rawTime():Number {
			return (_paused || (_totalTime !== 0 && _totalTime !== _totalDuration)) ? _totalTime : (_timeline.rawTime() - _startTime) * _timeScale;
		}
	
}artTime) * _timeScale;
		}
	
}