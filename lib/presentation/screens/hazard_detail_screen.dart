import 'package:flutter/material.dart';
import '../../core/constants/bedrock_constants.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/enums/domain_enums.dart';

// HazardDetailScreen is a StatelessWidget.
// It retrieves the data model passed from the feed screen using route arguments.
// Reference: https://docs.flutter.dev/cookbook/navigation/navigate-with-arguments
class HazardDetailScreen extends StatelessWidget {
  const HazardDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract the HazardDisplayModel passed as an argument via Named Routes.
    // ModalRoute.of(context) looks up the current routing settings on the Element Tree.
    // Reference: https://api.flutter.dev/flutter/widgets/ModalRoute/of.html
    final hazard =
        ModalRoute.of(context)!.settings.arguments as HazardDisplayModel;

    return Scaffold(
      appBar: AppBar(title: Text(hazard.type.displayName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BedrockConstants.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(hazard.type.emoji, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: BedrockConstants.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hazard.type.displayName.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: BedrockConstants.space4),
                        Text(
                          'Trust Index: ${(hazard.trustScore * 100).toInt()}%',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BedrockConstants.space24),
              const Divider(),
              const SizedBox(height: BedrockConstants.space16),
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: BedrockConstants.space8),
              Text(
                hazard.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
              const SizedBox(height: BedrockConstants.space24),
              const Divider(),
              const SizedBox(height: BedrockConstants.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reported By',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: BedrockConstants.space4),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/profile_detail',
                            arguments: {
                              'uid': hazard.reporterId,
                              'username': hazard.reporterName,
                            },
                          );
                        },
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Text(
                            hazard.reporterName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Reported Time',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: BedrockConstants.space4),
                      Text(
                        '${hazard.reportedAt.hour}:${hazard.reportedAt.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: BedrockConstants.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latitude',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: BedrockConstants.space4),
                      Text('${hazard.latitude}'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Longitude',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: BedrockConstants.space4),
                      Text('${hazard.longitude}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
