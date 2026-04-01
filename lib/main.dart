// ignore_for_file: use_build_context_synchronously
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'pages.dart';
import 'widgets/bluetooth_button.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'services/session_data_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('appBox');
  runApp(const MyApp());
}

/// ───────────────────────────────────────────────
/// RESPONSIVE DESIGN - IMPLEMENTATION STATUS
/// ───────────────────────────────────────────────
/// 
/// ✅ COMPLETED UPDATES (9 files):
/// 1. lib/main.dart - ResponsiveSize utility class
/// 2. lib/widgets/footer.dart - Footer responsive sizing
/// 3. lib/screens/record_mouth_opening.dart - Gauge painter responsive
/// 4. lib/screens/record_bite_force.dart - Gauge painter responsive  
/// 5. lib/widgets/ts_mouth_opening.dart - Chart axis responsive
/// 6. lib/widgets/ts_bite_force.dart - Chart axis responsive
/// 7. lib/screens/session_history.dart - Full responsive remake
/// 8. lib/screens/historical_statistics.dart - Full responsive remake
/// 9. lib/widgets/end_popup.dart - Dialog responsive updates
///
/// 🔶 NEEDS MANUAL UPDATES (5 files with code comments):
/// 1. lib/screens/ble.dart - Implement TabBarView for mobile
/// 2. lib/widgets/bluetooth_button.dart - Button icon size scaling
/// 3. lib/widgets/spatial_bite_force.dart - Box legend font sizes
/// 4. lib/widgets/ts_mouth_opening.dart - Chart label text sizes
/// 5. lib/widgets/ts_bite_force.dart - Chart label text sizes
///
/// KEY BREAKPOINTS:
/// - Mobile: < 400dp (0.8x scale)
/// - Phone: 400-600dp (0.9x scale)
/// - Tablet: 600-1200dp (1.0x base)
/// - Desktop: > 1200dp (1.1x scale)
/// ───────────────────────────────────────────────
class ResponsiveSize {
  static double getResponsiveWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getResponsiveHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isMobile(BuildContext context) {
    return getResponsiveWidth(context) < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = getResponsiveWidth(context);
    return width >= 600 && width < 1200;
  }

  static double responsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    final width = getResponsiveWidth(context);
    if (width < 600) return mobileSize;
    if (width < 1200) return tabletSize ?? mobileSize * 1.1;
    return desktopSize ?? mobileSize * 1.2;
  }

  static double responsivePadding(
    BuildContext context, {
    required double mobilePadding,
    double? tabletPadding,
    double? desktopPadding,
  }) {
    final width = getResponsiveWidth(context);
    if (width < 600) return mobilePadding;
    if (width < 1200) return tabletPadding ?? mobilePadding * 1.5;
    return desktopPadding ?? mobilePadding * 2.0;
  }

  static double scaleValue(BuildContext context, double baseValue) {
    final width = getResponsiveWidth(context);
    if (width < 400) return baseValue * 0.8;
    if (width < 600) return baseValue * 0.9;
    if (width < 1200) return baseValue;
    return baseValue * 1.1;
  }

  static EdgeInsets responsiveInsets(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? start,
    double? end,
  }) {
    final scale = scaleValue(context, 1.0);
    if (all != null) return EdgeInsets.all(all * scale);
    return EdgeInsets.fromLTRB(
      start ?? horizontal ?? 0,
      top ?? vertical ?? 0,
      end ?? horizontal ?? 0,
      bottom ?? vertical ?? 0,
    );
  }
}

/// Global Meter Gauge Limits RECORD MOUTH OPENING
const double gaugeMin = -180.0;
const double gaugeMax = 180.0;
const int minorDivisions = 12;
const int majorDivisions = 2;

/// Global Meter Gauge Limits RECORD BITE FORCE (BF)
const double bfGaugeMin = 0.0;
const double bfGaugeMax = 150.0;
const int bfMinorDivisions = 15;
const int bfMajorDivisions = 5;

Widget getPlatformWidget() {
  String platformText;
  if (Platform.isAndroid) {
    platformText = "Android detected";
  } else if (Platform.isIOS) {
    platformText = "iOS detected";
  } else {
    platformText = "Other platform detected";
  }
  return Text(
    platformText,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color.fromARGB(255, 186, 221, 250),
    ),
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}

class BatteryStatus extends StatelessWidget {
  const BatteryStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('appBox');

    return ValueListenableBuilder(
      valueListenable: box.listenable(keys: ['batteryPercent']),
      builder: (context, Box box, _) {
        final double battery =
            (box.get('batteryPercent', defaultValue: 100.0) as num).toDouble();

        IconData icon;

        if (battery > 75) {
          icon = Icons.battery_full;
        } else if (battery > 50) {
          icon = Icons.battery_5_bar;
        } else if (battery > 25) {
          icon = Icons.battery_3_bar;
        } else {
          icon = Icons.battery_1_bar;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              "${battery.toStringAsFixed(0)}%",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isBluetoothConnected = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OraStretch Tech',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'OraStretch Tech',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    getPlatformWidget(),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BatteryStatus(),
                  const SizedBox(width: 8),
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: BluetoothButton(
                      isConnected: isBluetoothConnected,
                      onConnectionChange: (isConnected) {
                        setState(() {
                          isBluetoothConnected = isConnected;
                        });
                      },
                      onDeviceSelected: (device) async {
                        if (device == null) return;
                        try {
                          final services = await device.discoverServices();
                          BluetoothCharacteristic? chosen;
                          for (final s in services) {
                            for (final c in s.characteristics) {
                              if (c.properties.notify) {
                                chosen = c;
                                break;
                              }
                            }
                            if (chosen != null) break;
                          }
                          if (chosen == null) {
                            for (final s in services) {
                              if (s.characteristics.isNotEmpty) {
                                chosen = s.characteristics.first;
                                break;
                              }
                            }
                          }
                          if (chosen != null) {
                            SessionDataService().attachBleCharacteristics(
                              chosen,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No notifiable characteristic found on device.',
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error discovering characteristics: ${e.toString()}',
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(16),
            child: Container(),
          ),
        ),
        body: MyPage(isBluetoothConnected: isBluetoothConnected),
      ),
    );
  }
}

class PageItem {
  final String id;
  final String title;
  final Widget Function() builder;

  PageItem({required this.id, required this.title, required this.builder});
}

class PageNavigation extends StatefulWidget {
  final List<PageItem> pages;
  final int currentPageIndex;
  final Function(int) onPageChange;
  final PageController pageController;

  const PageNavigation({
    super.key,
    required this.pages,
    required this.currentPageIndex,
    required this.onPageChange,
    required this.pageController,
  });

  @override
  State<PageNavigation> createState() => _PageNavigationState();
}

class _PageNavigationState extends State<PageNavigation> {
  final ScrollController _scrollController = ScrollController();
  double _indicatorPosition = 0.0;
  double _indicatorWidth = 0.0;
  late List<double> _tabWidths;
  late List<double> _tabPositions;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_updateIndicator);
    _calculateTabDimensions();
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_updateIndicator);
    super.dispose();
  }

  void _calculateTabDimensions() {
    _tabWidths = [];
    _tabPositions = [];
    double currentPosition = 24; // Initial left padding

    for (final page in widget.pages) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: page.title,
          style: const TextStyle(color: Color(0xFF374151)),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      _tabPositions.add(currentPosition);
      final tabWidth = textPainter.width + 48; // Add horizontal padding
      _tabWidths.add(tabWidth);
      currentPosition += tabWidth;
    }
  }

  void _updateIndicator() {
    setState(() {
      final pageValue = widget.pageController.page ?? 0.0;
      final pageIndex = pageValue.floor();
      final offset = pageValue - pageIndex;

      if (pageIndex < _tabPositions.length) {
        final currentTabPos = _tabPositions[pageIndex];
        final currentTabWidth = _tabWidths[pageIndex];

        if (pageIndex + 1 < _tabPositions.length) {
          // Interpolate between current and next tab
          final nextTabPos = _tabPositions[pageIndex + 1];
          final nextTabWidth = _tabWidths[pageIndex + 1];

          _indicatorPosition =
              currentTabPos + (nextTabPos - currentTabPos) * offset;
          _indicatorWidth =
              currentTabWidth + (nextTabWidth - currentTabWidth) * offset;
        } else {
          _indicatorPosition = currentTabPos;
          _indicatorWidth = currentTabWidth;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFBFDBFE))),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.pages.length, (index) {
                  return TextButton(
                    onPressed: () => widget.onPageChange(index),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF374151),
                    ),
                    child: Text(
                      widget.pages[index].title,
                      style: const TextStyle(color: Color(0xFF374151)),
                    ),
                  );
                }),
              ),
            ),
          ), // Animated underline that follows page swipes
          Positioned(
            bottom: 0,
            left: _indicatorPosition,
            child: Container(
              height: 2,
              width: _indicatorWidth,
              color: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}
