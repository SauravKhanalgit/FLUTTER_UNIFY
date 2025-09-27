/// Flutter Unify - One unified layer for Flutter apps across Mobile, Web, and Desktop
///
/// This library provides a single API surface that adapts to your platform,
/// offering native-grade performance and capabilities across all environments.
library flutter_unify;

// Core unified API
export 'src/unify.dart';

// Platform-specific implementations
export 'src/flutter_unify.dart';

// Web exports
export 'src/web/web_optimizer.dart';
export 'src/web/seo_renderer.dart';
export 'src/web/progressive_loader.dart';
export 'src/web/polyfills.dart';

// Desktop exports
export 'src/desktop/system_tray.dart';
export 'src/desktop/window_manager.dart';
export 'src/desktop/drag_drop.dart' hide DropTarget;
export 'src/desktop/shortcuts.dart';
export 'src/desktop/system_services.dart';

// Mobile exports
export 'src/mobile/native_bridge.dart';
export 'src/mobile/device_info.dart';
export 'src/mobile/mobile_services.dart';

// Common utilities
export 'src/common/platform_detector.dart';
export 'src/common/event_emitter.dart';
export 'src/common/capability_detector.dart';

// Widgets
export 'src/widgets/drop_target.dart';
export 'src/widgets/seo_widget.dart';
export 'src/widgets/unified_scaffold.dart';
