// Enums represent a fixed set of constant values.
// In Clean Architecture, we declare these in the Domain layer so that business logic
// states are completely decoupled from UI widgets (presentation layer).
// Reference: https://dart.dev/language/enums

// Represents the overall user safety index for Abbottabad.
enum SafetyStatus { safe, caution, critical }

// Supported types of natural disasters and road hazards in the Abbottabad region.
enum HazardType {
  landslide,
  flood,
  fog,
  roadBlock,
  accident,
  severeWeather,
  hurricane,
  earthquake,
  flashFlood,
  heatwave,
}

// Extension methods allow us to add custom getter functions directly to enums.
// This allows us to keep the enum representations clean while adding helper methods.
// Reference: https://dart.dev/language/extension-methods
extension HazardTypeX on HazardType {
  // Returns user-friendly text string representations.
  String get displayName {
    switch (this) {
      case HazardType.landslide:
        return 'Landslide';
      case HazardType.flood:
        return 'Flood';
      case HazardType.fog:
        return 'Dense Fog';
      case HazardType.roadBlock:
        return 'Road Block';
      case HazardType.accident:
        return 'Accident';
      case HazardType.severeWeather:
        return 'Severe Weather';
      case HazardType.hurricane:
        return 'Hurricane';
      case HazardType.earthquake:
        return 'Earthquake';
      case HazardType.flashFlood:
        return 'Flash Flood';
      case HazardType.heatwave:
        return 'Heatwave';
    }
  }

  // Returns emoji visuals to be rendered inside Text widgets.
  String get emoji {
    switch (this) {
      case HazardType.landslide:
        return '⛰️';
      case HazardType.flood:
        return '🌊';
      case HazardType.fog:
        return '🌫️';
      case HazardType.roadBlock:
        return '🚧';
      case HazardType.accident:
        return '🚨';
      case HazardType.severeWeather:
        return '⛈️';
      case HazardType.hurricane:
        return '🌀';
      case HazardType.earthquake:
        return '📳';
      case HazardType.flashFlood:
        return '💧';
      case HazardType.heatwave:
        return '🌡️';
    }
  }
}

// Tracks whether the user has voted (upvoted or downvoted) on a specific alert report.
enum VoteState { none, upvoted, downvoted }

// Ranks contributors based on their verification submission accuracy.
enum ReputationTier { rookie, helper, trusted, expert, veteran, admin }

enum HazardEventType { created, updated, resolved, escalated, expired }

extension HazardEventTypeX on HazardEventType {
  String get displayName {
    switch (this) {
      case HazardEventType.created:
        return 'Created';
      case HazardEventType.updated:
        return 'Updated';
      case HazardEventType.resolved:
        return 'Resolved';
      case HazardEventType.escalated:
        return 'Escalated';
      case HazardEventType.expired:
        return 'Expired';
    }
  }
}
