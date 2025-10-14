/// Flutter Map Configuration
///
/// Konfigurasi untuk flutter_map package:
/// - Tile layer URLs (OpenStreetMap)
/// - Default map center (Indonesia)
/// - Zoom levels
/// - Attribution settings
library;

import 'package:latlong2/latlong.dart';

class MapConfig {
  MapConfig._(); // Private constructor untuk prevent instantiation

  // ==================== TILE LAYER CONFIGURATION ====================

  /// OpenStreetMap tile server URL
  ///
  /// Template: https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
  /// {s}: subdomain (a, b, or c) untuk load balancing
  /// {z}: zoom level
  /// {x}: tile X coordinate
  /// {y}: tile Y coordinate
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Subdomains untuk load balancing (OpenStreetMap)
  static const List<String> osmSubdomains = ['a', 'b', 'c'];

  /// User agent untuk requests (required by OSM)
  ///
  /// OpenStreetMap requires user agent untuk identify aplikasi
  static const String userAgent = 'AIVIA - Aplikasi Asisten Alzheimer';

  /// Maximum concurrent tile requests
  ///
  /// Limit untuk prevent overwhelming tile servers
  static const int maxConcurrentRequests = 4;

  /// Tile size in pixels
  static const double tileSize = 256.0;

  // ==================== ZOOM CONFIGURATION ====================

  /// Minimum zoom level (world view)
  ///
  /// Level 3 shows entire world region
  static const double minZoom = 3.0;

  /// Maximum zoom level (street view)
  ///
  /// Level 18 shows detailed street-level view
  static const double maxZoom = 18.0;

  /// Default zoom level (city view)
  ///
  /// Level 15 shows neighborhood/district level
  /// Good balance untuk tracking pasien di area kota
  static const double defaultZoom = 15.0;

  /// Zoom level untuk "center on patient" action
  ///
  /// Level 17 shows detailed local area around patient
  static const double focusZoom = 17.0;

  // ==================== MAP CENTER CONFIGURATION ====================

  /// Default map center (Jakarta, Indonesia)
  ///
  /// Coordinates: -6.2088, 106.8456 (Monas)
  /// Akan di-override dengan patient location saat tersedia
  static const LatLng defaultCenter = LatLng(-6.2088, 106.8456);

  /// Indonesia bounding box (untuk restrict map movement - optional)
  ///
  /// Southwest: Sumatra barat daya
  /// Northeast: Papua timur laut
  /// Note: LatLngBounds from flutter_map, not const-able here
  /// Will be created in map screen initialization
  // static const LatLngBounds indonesiaBounds = LatLngBounds(...);
  static const LatLng indonesiaSouthwest = LatLng(-11.0, 95.0);
  static const LatLng indonesiaNortheast = LatLng(6.0, 141.0);

  // ==================== INTERACTION SETTINGS ====================

  /// Enable interactive controls (zoom, pan, rotate)
  static const bool enableInteraction = true;

  /// Enable rotation gestures
  static const bool enableRotation = false; // Disabled untuk simplicity

  /// Enable multi-finger gestures
  static const bool enableMultiFinger = true;

  /// Zoom speed multiplier
  static const double zoomSpeed = 1.0;

  /// Pan speed multiplier
  static const double panSpeed = 1.0;

  // ==================== ANIMATION SETTINGS ====================

  /// Animation duration untuk map movements
  static const Duration animationDuration = Duration(milliseconds: 500);

  /// Animation curve untuk smooth movements
  ///
  /// Curve.easeInOut provides smooth acceleration and deceleration
  // static const Curve animationCurve = Curves.easeInOut;
  // Note: Curve is not const, will be used directly in code

  // ==================== MARKER SETTINGS ====================

  /// Marker size (width & height)
  static const double markerSize = 50.0;

  /// Marker anchor point (center bottom)
  ///
  /// (0.5, 1.0) means marker "points" from center bottom
  /// Good untuk marker dengan pin/pointer shape
  static const double markerAnchorX = 0.5;
  static const double markerAnchorY = 1.0;

  // ==================== LOCATION ACCURACY SETTINGS ====================

  /// Accuracy threshold untuk show accuracy circle (meters)
  ///
  /// Jika accuracy > 50m, tampilkan circle indicator
  static const double accuracyThreshold = 50.0;

  /// Maximum accuracy radius untuk visualization (meters)
  ///
  /// Cap at 200m untuk prevent huge circles yang cover entire map
  static const double maxAccuracyRadius = 200.0;

  // ==================== LOCATION TRAIL SETTINGS ====================

  /// Maximum number of locations untuk trail polyline
  ///
  /// Keep manageable untuk performance
  static const int maxTrailPoints = 50;

  /// Polyline stroke width
  static const double trailStrokeWidth = 4.0;

  /// Polyline opacity
  static const double trailOpacity = 0.7;

  // ==================== CACHE SETTINGS ====================

  /// Enable tile caching
  ///
  /// Cache tiles locally untuk offline support
  static const bool enableCache = true;

  /// Cache duration (7 days)
  ///
  /// Tiles older than this akan di-refresh
  static const Duration cacheDuration = Duration(days: 7);

  /// Maximum cache size (100 MB)
  static const int maxCacheSize = 100 * 1024 * 1024; // bytes

  // ==================== ATTRIBUTION ====================

  /// OpenStreetMap attribution text
  ///
  /// Required by OSM terms of use
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// Show attribution widget
  static const bool showAttribution = true;

  // ==================== HELPER METHODS ====================

  /// Calculate zoom level based on accuracy
  ///
  /// Better accuracy → higher zoom (closer view)
  /// Worse accuracy → lower zoom (wider view)
  static double calculateZoomForAccuracy(double accuracyInMeters) {
    if (accuracyInMeters <= 10) return 18.0; // Very accurate - street level
    if (accuracyInMeters <= 25) return 17.0; // Good - local area
    if (accuracyInMeters <= 50) return 16.0; // Decent - neighborhood
    if (accuracyInMeters <= 100) return 15.0; // Fair - district
    return 14.0; // Poor - city level
  }

  /// Calculate center point dari list of locations
  ///
  /// Returns average LatLng untuk center map view
  static LatLng calculateCenter(List<LatLng> locations) {
    if (locations.isEmpty) {
      return defaultCenter;
    }

    if (locations.length == 1) {
      return locations.first;
    }

    // Calculate average
    double sumLat = 0;
    double sumLng = 0;

    for (final loc in locations) {
      sumLat += loc.latitude;
      sumLng += loc.longitude;
    }

    return LatLng(sumLat / locations.length, sumLng / locations.length);
  }

  /// Calculate span (delta) dari list of locations
  ///
  /// Returns LatLngSpan untuk fit bounds
  /// Used with MapController.fitBounds alternative
  static ({double latSpan, double lngSpan}) calculateSpan(
    List<LatLng> locations, {
    double paddingFactor = 0.2, // 20% padding
  }) {
    if (locations.isEmpty || locations.length == 1) {
      return (latSpan: 0.02, lngSpan: 0.02); // ~2km span
    }

    // Find min/max
    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final loc in locations) {
      if (loc.latitude < minLat) minLat = loc.latitude;
      if (loc.latitude > maxLat) maxLat = loc.latitude;
      if (loc.longitude < minLng) minLng = loc.longitude;
      if (loc.longitude > maxLng) maxLng = loc.longitude;
    }

    // Calculate span with padding
    final latSpan = (maxLat - minLat) * (1 + paddingFactor);
    final lngSpan = (maxLng - minLng) * (1 + paddingFactor);

    return (
      latSpan: latSpan.clamp(0.01, 180.0), // Min ~1km, max 180°
      lngSpan: lngSpan.clamp(0.01, 360.0), // Min ~1km, max 360°
    );
  }

  /// Calculate distance between two points (Haversine formula)
  ///
  /// Returns distance in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Format distance untuk display
  ///
  /// < 1000m: "250 m"
  /// >= 1000m: "1.5 km"
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }
}
