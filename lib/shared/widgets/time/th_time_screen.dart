// lib/core/time/th_time_text.dart
// ──────────────────────────────────────────────────────────────────────────────
// Thai time widget + authority (Online via NTP with offline/HTTP fallback)
// - Accurate to network time when available (NTP). Falls back to HTTP (web) or
//   device time when offline.
// - Stream-based ticker (1s) shared across app.
// - Route-based visibility: show only on pages (routes) you specify.
// - Zero-DST assumption is valid for Asia/Bangkok (UTC+7 all year).
//
// Dependencies (pubspec.yaml):
//   dependencies:
//     intl: ^0.19.0
//     ntp: ^2.0.0
//     http: ^1.2.0
//
// App setup:
//   1) Register the RouteObserver in your MaterialApp:
//        import 'package:smarttelemed_v4/shared/services/time/th_time_text.dart';
//        MaterialApp(
//          navigatorObservers: [appRouteObserver],
//          // ...
//        )
//
//   2) Place where needed:
//        const ThTimeText(pattern: 'HH:mm:ss')
//
//      Or auto-hide unless current route matches:
//        const TimeTextOnRoutes(
//          routes: {'/device_screen', '/vitals'},
//          child: ThTimeText(pattern: 'HH:mm:ss'),
//        )
//
//   3) Optional: force an early sync after login:
//        ThTimeAuthority.I.syncNtp();
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:ntp/ntp.dart';

/// Global route observer for route-aware visibility.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  Time Authority (Thai time, NTP-corrected when online)                  ║
/* ╚══════════════════════════════════════════════════════════════════════════╝ */
class ThTimeAuthority with ChangeNotifier {
  ThTimeAuthority._();
  static final ThTimeAuthority I = ThTimeAuthority._();

  // Asia/Bangkok is UTC+7, no DST
  static const Duration _thaiOffset = Duration(hours: 7);

  // Current measured delta between device clock and network time (ms precision).
  Duration _delta = Duration.zero;
  bool _hasSyncedOnce = false;
  bool _lastSyncOnline = false; // true if last sync hit NTP/HTTP
  DateTime? _lastSyncAt; // local time of last sync attempt

  // Ticking stream (1s) shared across app
  final _controller = StreamController<DateTime>.broadcast();
  Stream<DateTime> get stream => _controller.stream;

  Timer? _tick; // 1s ticker
  Timer? _resync; // periodic NTP/HTTP resync

  /// Current Thai time (device UTC + offset + network delta if any)
  DateTime now() => DateTime.now().toUtc().add(_thaiOffset + _delta);

  /// Whether our current output is based on network time (true) or device only (false).
  bool get isOnlineAccurate => _hasSyncedOnce && _lastSyncOnline;

  /// Last time we attempted a sync (local device time)
  DateTime? get lastSyncAt => _lastSyncAt;

  /// Start ticking & schedule resync. Safe to call multiple times.
  void ensureStarted() {
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(now());
    });
    _resync ??= Timer.periodic(const Duration(minutes: 10), (_) {
      // keep delta fresh; quiet failure if offline
      syncNtp();
    });

    // Do an initial background sync shortly after start
    if (!_hasSyncedOnce) {
      // Stagger a bit so first frame is fast
      Future<void>.delayed(const Duration(milliseconds: 100), syncNtp);
    }
  }

  /// Force a network-time sync. If it fails (offline), we keep the previous delta.
  Future<void> syncNtp({Duration timeout = const Duration(seconds: 2)}) async {
    _lastSyncAt = DateTime.now();

    // Web cannot use UDP (NTP). Use HTTP fallback.
    if (kIsWeb) {
      final ok = await _syncViaHttp(timeout: const Duration(seconds: 3));
      _lastSyncOnline = ok;
      _hasSyncedOnce = true;
      notifyListeners();
      return;
    }

    // Try multiple NTP hosts first
    const hosts = <String>[
      'time.google.com',
      'time1.google.com',
      'pool.ntp.org',
      'time.cloudflare.com',
      'time.nist.gov',
    ];

    for (final host in hosts) {
      try {
        final offsetMs = await NTP.getNtpOffset(
          lookUpAddress: host,
          timeout: timeout,
        );
        _delta = Duration(milliseconds: offsetMs);
        _lastSyncOnline = true;
        _hasSyncedOnce = true;
        notifyListeners();
        return; // success
      } catch (_) {
        // try next host
      }
    }

    // If all NTP attempts failed, try HTTP fallback (works on all platforms)
    final ok = await _syncViaHttp(timeout: const Duration(seconds: 3));
    _lastSyncOnline = ok;
    _hasSyncedOnce = true;
    notifyListeners();
  }

  /// HTTP (REST) fallback: fetch UTC time and compute delta.
  Future<bool> _syncViaHttp({Duration timeout = const Duration(seconds: 3)}) async {
    final endpoints = <Uri>[
      Uri.parse('https://worldtimeapi.org/api/timezone/Etc/UTC'),
      Uri.parse('https://timeapi.io/api/Time/current/zone?timeZone=UTC'),
    ];

    for (final uri in endpoints) {
      try {
        final res = await http.get(uri).timeout(timeout);
        if (res.statusCode != 200) continue;

        final map = jsonDecode(res.body) as Map<String, dynamic>;
        // worldtimeapi: 'utc_datetime' or 'datetime'
        // timeapi.io  : 'dateTime'
        final iso = (map['utc_datetime'] as String?) ??
            (map['datetime'] as String?) ??
            (map['dateTime'] as String?);
        if (iso == null) continue;

        final netUtc = DateTime.parse(iso).toUtc();
        final devUtc = DateTime.now().toUtc();
        _delta = netUtc.difference(devUtc);
        return true;
      } catch (_) {
        // next endpoint
      }
    }
    return false;
  }

  @override
  void dispose() {
    _tick?.cancel();
    _resync?.cancel();
    _controller.close();
    super.dispose();
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
/* ║  Time Text Widget (with Thai date option & optional icon)               ║
   ╚══════════════════════════════════════════════════════════════════════════╝ */
class ThTimeText extends StatefulWidget {
  const ThTimeText({
    super.key,
    this.pattern = 'HH:mm:ss',
    this.style,
    this.showSourceBadge = true,
    this.prefix,
    this.suffix,
    this.locale,
    this.textAlign,

    // === Thai date options ===
    this.showThaiDate = false,          // "วันที่ … เวลา …"
    this.useBuddhistYear = true,        // พ.ศ. (+543)
    this.dateTimeSeparator = ' เวลา ',  // between date and time
    this.appendThaiNi = true,           // append " น."

    // === Icon options ===
    this.showIcon = false,              // show time-of-day icon
    this.iconData,                      // override the icon
    this.iconGap = 6.0,
    this.iconSize,
    this.iconColor,
  });

  /// intl DateFormat pattern, e.g. 'HH:mm', 'dd MMM yyyy HH:mm:ss'
  final String pattern;
  final TextStyle? style;
  final bool showSourceBadge; // show NTP/Device chip
  final Widget? prefix;
  final Widget? suffix;
  final String? locale; // e.g., 'th_TH'
  final TextAlign? textAlign;

  // Thai date opts
  final bool showThaiDate;
  final bool useBuddhistYear;
  final String dateTimeSeparator;
  final bool appendThaiNi;

  // Icon opts
  final bool showIcon;
  final IconData? iconData;
  final double iconGap;
  final double? iconSize;
  final Color? iconColor;

  @override
  State<ThTimeText> createState() => _ThTimeTextState();
}

class _ThTimeTextState extends State<ThTimeText> {
  late final ThTimeAuthority _auth;

  @override
  void initState() {
    super.initState();
    _auth = ThTimeAuthority.I;
    _auth.ensureStarted();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium;

    return AnimatedBuilder(
      animation: _auth,
      builder: (context, _) {
        return StreamBuilder<DateTime>(
          stream: _auth.stream,
          initialData: _auth.now(),
          builder: (context, snap) {
            final dt = snap.data ?? _auth.now();
            final text = _buildDisplayText(
              dt,
              pattern: widget.pattern,
              locale: widget.locale,
              showThaiDate: widget.showThaiDate,
              useBuddhistYear: widget.useBuddhistYear,
              dateTimeSeparator: widget.dateTimeSeparator,
              appendThaiNi: widget.appendThaiNi,
            );

            Widget content = _composeTextWithOptionalIcon(
              dt,
              text,
              context,
              baseStyle,
            );

            // Apply text alignment, if requested
            if (widget.textAlign != null) {
              content = Align(
                alignment: _alignFromTextAlign(widget.textAlign!),
                child: content,
              );
            }

            // Add source badge and prefix/suffix
            final rowChildren = <Widget>[
              if (widget.prefix != null) widget.prefix!,
              Flexible(child: content),
              if (widget.showSourceBadge) ...[
                const SizedBox(width: 6),
                _SourceBadge(
                  online: _auth.isOnlineAccurate,
                  lastSyncAt: _auth.lastSyncAt,
                ),
              ],
              if (widget.suffix != null) widget.suffix!,
            ];

            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: rowChildren,
            );
          },
        );
      },
    );
  }

  Widget _composeTextWithOptionalIcon(
    DateTime now,
    String text,
    BuildContext context,
    TextStyle? baseStyle,
  ) {
    final txt = Text(
      text,
      style: baseStyle,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );

    if (!widget.showIcon) return txt;

    final resolvedIcon = widget.iconData ?? _iconFor(now);
    final resolvedIconSize =
        widget.iconSize
            ?? baseStyle?.fontSize
            ?? Theme.of(context).textTheme.bodyMedium?.fontSize
            ?? 14.0;
    final resolvedIconColor =
        widget.iconColor
            ?? baseStyle?.color
            ?? Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(resolvedIcon, size: resolvedIconSize, color: resolvedIconColor),
        SizedBox(width: widget.iconGap),
        txt,
      ],
    );
  }

  String _buildDisplayText(
    DateTime dt, {
    required String pattern,
    String? locale,
    required bool showThaiDate,
    required bool useBuddhistYear,
    required String dateTimeSeparator,
    required bool appendThaiNi,
  }) {
    final loc = locale ?? 'th';
    if (!showThaiDate) {
      return DateFormat(pattern, loc).format(dt);
    }

    final dayMonth = DateFormat('d MMMM', loc).format(dt);
    final yearNum = useBuddhistYear ? dt.year + 543 : dt.year;
    final timeStr = DateFormat(pattern, loc).format(dt);

    final base = 'วันที่ $dayMonth $yearNum$dateTimeSeparator$timeStr';
    return appendThaiNi ? '$base น.' : base;
  }

  IconData _iconFor(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 10) return Icons.wb_twilight;   // early morning
    if (h >= 10 && h < 17) return Icons.wb_sunny;      // day
    if (h >= 17 && h < 20) return Icons.wb_twilight;   // evening
    return Icons.nightlight_round;                      // night
  }

  Alignment _alignFromTextAlign(TextAlign ta) {
    switch (ta) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.left:
      case TextAlign.start:
      default:
        return Alignment.centerLeft;
    }
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
/* ║  Ultra-compact time text (optional Thai date; no badges)                ║
   ╚══════════════════════════════════════════════════════════════════════════╝ */
class ThTimeTextCompact extends StatefulWidget {
  const ThTimeTextCompact({
    super.key,
    this.pattern = 'HH:mm',
    this.style,
    this.locale,
    this.textAlign,
    this.ignorePointer = true,

    // Thai date options
    this.showThaiDate = false,
    this.useBuddhistYear = true,
    this.dateTimeSeparator = ' เวลา ',
    this.appendThaiNi = true,

    // Icon options
    this.showIcon = false,
    this.iconData,
    this.iconGap = 6.0,
    this.iconSize,
    this.iconColor,
  });

  final String pattern;
  final TextStyle? style;
  final String? locale;
  final TextAlign? textAlign;
  final bool ignorePointer;

  // Thai date opts
  final bool showThaiDate;
  final bool useBuddhistYear;
  final String dateTimeSeparator;
  final bool appendThaiNi;

  // Icon opts
  final bool showIcon;
  final IconData? iconData;
  final double iconGap;
  final double? iconSize;
  final Color? iconColor;

  @override
  State<ThTimeTextCompact> createState() => _ThTimeTextCompactState();
}

class _ThTimeTextCompactState extends State<ThTimeTextCompact> {
  late final ThTimeAuthority _auth;

  @override
  void initState() {
    super.initState();
    _auth = ThTimeAuthority.I;
    _auth.ensureStarted();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium;

    final textWidget = StreamBuilder<DateTime>(
      stream: _auth.stream,
      initialData: _auth.now(),
      builder: (context, snap) {
        final dt = snap.data ?? _auth.now();
        final loc = widget.locale ?? 'th';

        String display;
        if (widget.showThaiDate) {
          final dayMonth = DateFormat('d MMMM', loc).format(dt);
          final yearNum = widget.useBuddhistYear ? dt.year + 543 : dt.year;
          final timeStr = DateFormat(widget.pattern, loc).format(dt);
          final base = 'วันที่ $dayMonth $yearNum${widget.dateTimeSeparator}$timeStr';
          display = widget.appendThaiNi ? '$base น.' : base;
        } else {
          display = DateFormat(widget.pattern, loc).format(dt);
        }

        final txt = Text(
          display,
          style: baseStyle,
          textAlign: widget.textAlign,
          overflow: TextOverflow.visible,
          softWrap: false,
        );

        if (!widget.showIcon) return txt;

        final resolvedIcon = widget.iconData ?? _iconFor(dt);
        final resolvedIconSize =
            widget.iconSize
                ?? baseStyle?.fontSize
                ?? Theme.of(context).textTheme.bodyMedium?.fontSize
                ?? 14.0;
        final resolvedIconColor =
            widget.iconColor
                ?? baseStyle?.color
                ?? Theme.of(context).colorScheme.onSurface;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(resolvedIcon, size: resolvedIconSize, color: resolvedIconColor),
            SizedBox(width: widget.iconGap),
            txt,
          ],
        );
      },
    );

    return widget.ignorePointer ? IgnorePointer(child: textWidget) : textWidget;
  }

  IconData _iconFor(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 10) return Icons.wb_twilight;
    if (h >= 10 && h < 17) return Icons.wb_sunny;
    if (h >= 17 && h < 20) return Icons.wb_twilight;
    return Icons.nightlight_round;
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
/* ║  Small helper widgets                                                   ║
   ╚══════════════════════════════════════════════════════════════════════════╝ */
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.online, required this.lastSyncAt});
  final bool online; // true=Network (NTP/HTTP), false=Device
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = online
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.surfaceVariant;
    final fg = online
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final label = online ? 'NTP' : 'Device';

    final tooltip = online
        ? 'Online (ซิงค์ NTP/HTTP)\nล่าสุด: ${_fmt(lastSyncAt)}'
        : 'Offline (ใช้เวลาเครื่อง)\nล่าสุด: ${_fmt(lastSyncAt)}';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(online: online),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime? t) {
    if (t == null) return '-';
    return DateFormat('HH:mm:ss').format(t);
    // Note: using device locale here is fine; this is only a tooltip hint.
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.online});
  final bool online;
  @override
  Widget build(BuildContext context) {
    final color = online ? Colors.green : Colors.grey;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
/* ║  Route-based visibility wrapper                                         ║
   ╚══════════════════════════════════════════════════════════════════════════╝ */
/// Wrap any child (e.g., [ThTimeText]) and it will only be visible when the
/// current route name matches one of [routes]. Requires [appRouteObserver]
/// to be installed in MaterialApp.navigatorObservers.
class TimeTextOnRoutes extends StatefulWidget {
  const TimeTextOnRoutes({
    super.key,
    required this.routes,
    required this.child,
    this.hideWhenUnknown = true,
    this.caseSensitive = false,
  });

  /// Set of route names to show on. Example: {'/device_screen', '/vitals'}
  final Set<String> routes;

  /// The widget to show/hide (usually [ThTimeText]).
  final Widget child;

  /// If route has no name, hide by default.
  final bool hideWhenUnknown;

  /// Whether route name matching is case-sensitive.
  final bool caseSensitive;

  @override
  State<TimeTextOnRoutes> createState() => _TimeTextOnRoutesState();
}

class _TimeTextOnRoutesState extends State<TimeTextOnRoutes> with RouteAware {
  ModalRoute<dynamic>? _route;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route is PageRoute) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      if (route is PageRoute) {
        appRouteObserver.subscribe(this, route);
      }
      _updateVisibility();
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => _updateVisibility();
  @override
  void didPopNext() => _updateVisibility();
  @override
  void didPop() => _updateVisibility();
  @override
  void didPushNext() => _updateVisibility();

  void _updateVisibility() {
    final name = _route?.settings.name;
    if (name == null) {
      setState(() => _visible = !widget.hideWhenUnknown);
      return;
    }
    final want = widget.caseSensitive
        ? widget.routes.contains(name)
        : widget.routes.map((e) => e.toLowerCase()).contains(name.toLowerCase());
    setState(() => _visible = want);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _visible ? widget.child : const SizedBox.shrink(),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════╗
/* ║  Convenience: tiny app bar title & actions                             ║
   ╚══════════════════════════════════════════════════════════════════════════╝ */
class ThTimeAppBarTitle extends StatelessWidget {
  const ThTimeAppBarTitle({super.key});
  @override
  Widget build(BuildContext context) {
    return const ThTimeText(
      pattern: 'HH:mm:ss',
      showSourceBadge: true,
      showIcon: true,
    );
  }
}

class ThTimeAppBarActionRoutes extends StatelessWidget {
  const ThTimeAppBarActionRoutes({
    super.key,
    required this.routes,
    this.pattern = 'HH:mm',
    this.locale,
    this.showWhenUnknown = false,
    this.debugPrintRouteName = false,
    this.showThaiDate = false,
  });

  /// Set of route names to show time on AppBar actions
  final Set<String> routes;
  final String pattern;
  final String? locale;

  /// If true and current route name is null/unknown, we still show the clock
  final bool showWhenUnknown;

  /// Debug helper: print current route name once at build
  final bool debugPrintRouteName;

  /// Optionally show Thai date in actions as well
  final bool showThaiDate;

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name;
    if (debugPrintRouteName) {
      // ignore: avoid_print
      print('[ThTimeAppBarActionRoutes] route = ${routeName ?? 'null'}');
    }
    return TimeTextOnRoutes(
      routes: routes,
      hideWhenUnknown: !showWhenUnknown,
      child: ThTimeTextCompact(
        pattern: pattern,
        locale: locale,
        style: Theme.of(context).textTheme.titleMedium,
        ignorePointer: true,
        showThaiDate: showThaiDate,
        showIcon: true,
      ),
    );
  }
}

/// Reusable set for your project: show only on these routes.
const kTimeOnAppBarRoutes = {
  '/profile',
  '/profilept',
  '/mainpt',
  '/vitalsign',
};

// Example usage on any page Scaffold:
// AppBar(
//   title: const Text('Title'),
//   actions: const [
//     ThTimeAppBarActionRoutes(routes: kTimeOnAppBarRoutes, showThaiDate: false),
//   ],
// )
