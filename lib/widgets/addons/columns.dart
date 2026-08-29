/// How many columns a listing should use for a given width.
///
/// Driven by width rather than orientation: a tablet held upright is wider
/// than a phone in landscape, and it was showing one card across 1067 dp
/// before this existed. Aiming at a column width rather than a breakpoint
/// keeps phone/phone-landscape/tablet/tablet-landscape at 1/2/3/4 without
/// naming any of them.
int columnsForWidth(double width, {double idealColumnWidth = 400}) {
  return (width / idealColumnWidth).round().clamp(1, 4);
}
