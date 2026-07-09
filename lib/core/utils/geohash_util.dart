class GeohashUtil {
  static const String _alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encodes a latitude and longitude into a geohash string.
  static String encode(double latitude, double longitude, {int precision = 9}) {
    final List<int> bits = [16, 8, 4, 2, 1];

    double latMin = -90.0;
    double latMax = 90.0;
    double lonMin = -180.0;
    double lonMax = 180.0;

    final StringBuffer geohash = StringBuffer();
    int bit = 0;
    int ch = 0;
    bool isEven = true; // Even bit = longitude, Odd bit = latitude

    while (geohash.length < precision) {
      double mid;
      if (isEven) {
        mid = (lonMin + lonMax) / 2;
        if (longitude > mid) {
          ch |= bits[bit];
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        mid = (latMin + latMax) / 2;
        if (latitude > mid) {
          ch |= bits[bit];
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(_alphabet[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return geohash.toString();
  }

  /// Calculates a list of geohash prefixes that cover a bounding box (for query expansion).
  /// For this crowdsourced app, standard geohash prefix queries will look at prefix matching
  /// on lengths corresponding to search radius (e.g. 5-character geohash corresponds to ~4.9km).
  static String getQueryPrefix(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    // 1 char: 5,009km x 4,992km
    // 2 char: 1,252km x 625km
    // 3 char: 156km x 156km
    // 4 char: 39km x 19.5km
    // 5 char: 4.9km x 4.9km
    // 6 char: 1.2km x 0.6km
    // 7 char: 152m x 152m
    // 8 char: 38m x 19m
    int precision = 9;
    if (radiusKm > 50) {
      precision = 3;
    } else if (radiusKm > 10) {
      precision = 4;
    } else if (radiusKm > 2) {
      precision = 5;
    } else if (radiusKm > 0.5) {
      precision = 6;
    } else {
      precision = 7;
    }
    return encode(latitude, longitude, precision: precision);
  }
}
