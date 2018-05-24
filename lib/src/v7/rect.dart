import "dart:math" as Math;

class Rect {
  int left;
  int top;
  int right;
  int bottom;

  Rect();

  Rect.ltrb(int left, int top, int right, int bottom) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  Rect.fromRect(Rect r) {
    if ( r == null ) {
      left = top = right = bottom = 0;
    } else {
      this.left = r.left;
      this.top = r.top;
      this.right = r.right;
      this.bottom = r.bottom;
    }
  }

  bool get isEmpty => left >= right || top >= bottom;

  void setEmpty() {
    left = right = bottom = 0;
  }

  int get width => right - left;

  int get height => bottom - top;

  int get centerX => (left + right) >> 1;

  int get centerY => (top + bottom) >> 1;

  double get exactCenterX => (left + right) * 0.5;

  double get exactCenterY => (top + bottom) * 0.5;


  void set(int left, int top, int right, int bottom) {
    this.left = left;
    this.top = top;
    this.right = right;
    this.bottom = bottom;
  }

  void setWithRect(Rect r) {
    this.left = r.left;
    this.top = r.top;
    this.right = r.right;
    this.bottom = r.bottom;
  }

  void offset(int dx, int dy) {
    left += dx;
    top += dy;
    right += dx;
    bottom += dy;
  }

  void offsetTo(int newLeft, int newTop) {
    this.right += newLeft - left;
    this.bottom += newTop - top;
    this.left = newLeft;
    this.top = newTop;
  }

  void inset(int dx, int dy) {
    this.left += dx;
    this.top += dy;
    this.right -= dx;
    this.bottom -= dy;
  }

  void insetWithRect(Rect insets) {
    left += insets.left;
    top += insets.top;
    right -= insets.right;
    bottom -= insets.bottom;
  }

  void insetLTRB(int left, int top, int right, int bottom) {
    this.left += left;
    this.top += top;
    this.right -= right;
    this.bottom -= bottom;
  }

  bool contains(int x, int y) {
    return left < right && top < bottom  // check for empty first
            && x >= left && x < right && y >= top && y < bottom;
  }

  bool containsLTRB(int left, int top, int right, int bottom) {
    // check for empty first
    return this.left < this.right && this.top < this.bottom
      // now check for containment
      && this.left <= left && this.top <= top
      && this.right >= right && this.bottom >= bottom;
  }

  bool containsRect(Rect r) {
               // check for empty first
    return this.left < this.right && this.top < this.bottom
            // now check for containment
            && left <= r.left && top <= r.top && right >= r.right && bottom >= r.bottom;
  }

  bool intersect(int left, int top, int right, int bottom) {
    if (this.left < right && left < this.right && this.top < bottom && top < this.bottom) {
      if (this.left < left) this.left = left;
      if (this.top < top) this.top = top;
      if (this.right > right) this.right = right;
      if (this.bottom > bottom) this.bottom = bottom;
      return true;
    }
    return false;
  }


  bool intersectWithRect(Rect r) {
      return intersect(r.left, r.top, r.right, r.bottom);
  }


  /*
  * If rectangles a and b intersect, return true and set this rectangle to
  * that intersection, otherwise return false and do not change this
  * rectangle. No check is performed to see if either rectangle is empty.
  * To just test for intersection, use intersects()
  *
  * @param a The first rectangle being intersected with
  * @param b The second rectangle being intersected with
  * @return true iff the two specified rectangles intersect. If they do, set
  *              this rectangle to that intersection. If they do not, return
  *              false and do not change this rectangle.
  */
  bool setIntersect(Rect a, Rect b) {
    if (a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom) {
      left = Math.max(a.left, b.left);
      top = Math.max(a.top, b.top);
      right = Math.min(a.right, b.right);
      bottom = Math.min(a.bottom, b.bottom);
      return true;
    }
    return false;
  }

  bool intersects(int left, int top, int right, int bottom) {
    return this.left < right && left < this.right && this.top < bottom && top < this.bottom;
  }

  static bool intersecting(Rect a, Rect b) {
    return a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;
  }

  @override
    int get hashCode {
      int result = left;
      result = 31 * result + top;
      result = 31 * result + right;
      result = 31 * result + bottom;
      return result;
    }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Rect &&
            left == other.left &&
            top == other.top &&
            right == other.right &&
            bottom == other.bottom;

}