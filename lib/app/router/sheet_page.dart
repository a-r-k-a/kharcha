import 'package:material_ui/material_ui.dart';

/// A GoRouter page presented as a modal bottom sheet, so sheets are real
/// routes: deep-linkable, and dismissed with the system back gesture.
class SheetPage<T> extends Page<T> {
  const SheetPage({required this.child, super.key, super.name});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return ModalBottomSheetRoute<T>(
      settings: this,
      builder: (_) => child,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
    );
  }
}
