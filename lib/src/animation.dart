/// Code based on charts.js by Nick Downie, http://chartjs.org/
///
/// (Partial) Dart implementation done by Symcon GmbH, Tim Rasim
///
/// Easing functions adapted from Robert Penner's easing equations
/// http://www.robertpenner.com/easing/
library chart.src.animation;

import 'dart:math';

/// The easing function type.
///
/// An easing function takes an input number [t] in range 0..1, inclusive, and
/// returns a non-negative value. In addition, the function must return 1 for
/// [t] = 1.
typedef double EasingFunction(double t);

double linear(double t) => t;

double easeInQuad(double t) => t * t;

double easeOutQuad(double t) => t * (2 - t);

double easeInOutQuad(double t) {
  var value = t * 2;
  if (value < 1) return .5 * value * value;
  value--;
  return .5 * (1 - value * (value - 2));
}

double easeInCubic(double t) => t * t * t;

double easeOutCubic(double t) {
  final value = t - 1;
  return value * value * value + 1;
}

double easeInOutCubic(double t) {
  var value = t * 2;
  if (value < 1) return .5 * value * value * value;
  value -= 2;
  return .5 * (value * value * value + 2);
}

double easeInQuart(double t) => t * t * t * t;

double easeOutQuart(double t) {
  final value = t - 1;
  return 1 - value * value * value * value;
}

double easeInOutQuart(double t) {
  var value = t * 2;

  if (value < 1) return .5 * value * value * value * value;
  value -= 2;
  return .5 * (2 - value * value * value * value);
}

double easeInQuint(double t) => t * t * t * t * t;

double easeOutQuint(double t) {
  final value = t - 1;
  return value * value * value * value * value + 1;
}

double easeInOutQuint(double t) {
  var value = t * 2;
  if (value < 1) return .5 * value * value * value * value * value;
  value -= 2;
  return .5 * (value * value * value * value * value + 2);
}

double easeInSine(double t) => 1 - cos(t * pi / 2);

double easeOutSine(double t) => sin(t * pi / 2);

double easeInOutSine(double t) => .5 * (1 - cos(pi * t));

double easeInExpo(double t) => (t == 0.0) ? 1.0 : pow(2, 10 * (t - 1));

double easeOutExpo(double t) => (t == 1.0) ? 1.0 : (1 - pow(2, -10 * t));

double easeInOutExpo(double t) {
  if (t == 0.0) return 0.0;
  if (t == 1.0) return 1.0;

  var value = t * 2;
  if (value < 1) return 1 / 2 * pow(2, 10 * (value - 1));
  return .5 * (-pow(2, -10 * --value) + 2);
}

double easeInCirc(double t) {
  if (t >= 1) return t;
  return 1 - sqrt(1 - t * t);
}

double easeOutCirc(double t) => sqrt(1 - (t - 1) * t);

double easeInOutCirc(double t) {
  var value = t * 2;

  if (value < 1) return -.5 * (sqrt(1 - value * value) - 1);
  value -= 2;
  return .5 * (sqrt(1 - value * value) + 1);
}

double easeInElastic(double t) {
  var value = t;
  var s = 1.70158;
  var p = 0.0;
  var a = 1.0;
  if (value == 0) return 0.0;
  if (value == 1) return 1.0;
  if (p == 0) p = 0.3;
  if (a < 1) {
    a = 1.0;
    s = p / 4;
  } else {
    s = p / (2 * pi) * asin(1 / a);
  }
  value--;
  return -(a * pow(2, 10 * value) * sin((value - s) * (2 * pi) / p));
}

double easeOutElastic(double t) {
  var s = 1.70158;
  var p = 0.0;
  var a = 1.0;
  if (t == 0) return 0.0;
  if (t == 1) return 1.0;
  if (p == 0) p = 0.3;
  if (a < 1) {
    a = 1.0;
    s = p / 4;
  } else {
    s = p / (2 * pi) * asin(1 / a);
  }
  return a * pow(2, -10 * t) * sin((t - s) * (2 * pi) / p) + 1;
}

double easeInOutElastic(double t) {
  var value = t;
  var s = 1.70158;
  var p = 0.0;
  var a = 1.0;
  if (t == 0.0) return 0.0;
  if (t == 1.0) return 1.0;
  if (p == 0.0) p = 1 * (.3 * 1.5);
  if (a < 1) {
    a = 1.0;
    s = p / 4;
  } else {
    s = p / (2 * pi) * asin(1 / a);
  }
  value = 2 * value - 1;
  if (value < 0) return -.5 * (a * pow(2, 10 * value) * sin((value - s) * (2 * pi) / p));
  return a * pow(2, -10 * value) * sin((value - s) * (2 * pi) / p) * .5 + 1;
}

double easeInBack(double t) {
  const s = 1.70158;
  return t * t * ((s + 1) * t - s);
}

double easeOutBack(double t) {
  var value = t;
  const s = 1.70158;
  value--;
  return value * value * ((s + 1) * value + s) + 1;
}

double easeInOutBack(double t) {
  const s = 1.70158 * 1.525;
  var value = t * 2;
  if (value < 1) return .5 * (value * value * ((s + 1) * value - s));
  value -= 2;
  return .5 * (value * value * ((s + 1) * value + s) + 2);
}

double easeInBounce(double t) => 1 - easeOutBounce(1 - t);

double easeOutBounce(double t) {
  var value = t;
  if (value < 1 / 2.75) {
    return 7.5625 * value * value;
  } else if (value < 2 / 2.75) {
    value -= 1.5 / 2.75;
    return 7.5625 * value * value + .75;
  } else if (value < 2.5 / 2.75) {
    value -= 2.25 / 2.75;
    return 7.5625 * value * value + .9375;
  } else {
    value -= 2.625 / 2.75;
    return 7.5625 * value * value + .984375;
  }
}

double easeInOutBounce(double t) {
  if (t < .5) return easeInBounce(t * 2) * .5;
  return easeOutBounce(t * 2 - 1) * .5 + 1 * .5;
}

/// Returns the easing function with the given [name].
///
/// [name] can be an [EasingFunction] or a [String] specifying the name of one
/// of the easing functions defined above.
EasingFunction getEasingFunction(Object name) {
  if (name is EasingFunction) return name;
  switch (name) {
    case 'linear':
      return linear;
    case 'easeInQuad':
      return easeInQuad;
    case 'easeOutQuad':
      return easeOutQuad;
    case 'easeInOutQuad':
      return easeInOutQuad;
    case 'easeInCubic':
      return easeInCubic;
    case 'easeOutCubic':
      return easeOutCubic;
    case 'easeInOutCubic':
      return easeInOutCubic;
    case 'easeInQuart':
      return easeInQuart;
    case 'easeOutQuart':
      return easeOutQuart;
    case 'easeInOutQuart':
      return easeInOutQuart;
    case 'easeInQuint':
      return easeInQuint;
    case 'easeOutQuint':
      return easeOutQuint;
    case 'easeInOutQuint':
      return easeInOutQuint;
    case 'easeInSine':
      return easeInSine;
    case 'easeOutSine':
      return easeOutSine;
    case 'easeInOutSine':
      return easeInOutSine;
    case 'easeInExpo':
      return easeInExpo;
    case 'easeOutExpo':
      return easeOutExpo;
    case 'easeInOutExpo':
      return easeInOutExpo;
    case 'easeInCirc':
      return easeInCirc;
    case 'easeOutCirc':
      return easeOutCirc;
    case 'easeInOutCirc':
      return easeInOutCirc;
    case 'easeInElastic':
      return easeInElastic;
    case 'easeOutElastic':
      return easeOutElastic;
    case 'easeInOutElastic':
      return easeInOutElastic;
    case 'easeInBack':
      return easeInBack;
    case 'easeOutBack':
      return easeOutBack;
    case 'easeInOutBack':
      return easeInOutBack;
    case 'easeInBounce':
      return easeInBack;
    case 'easeOutBounce':
      return easeOutBounce;
    case 'easeInOutBounce':
      return easeInOutBounce;
    default:
      throw new ArgumentError.value(name, 'name');
  }
}
