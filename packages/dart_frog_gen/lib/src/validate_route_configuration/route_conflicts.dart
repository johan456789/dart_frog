import 'package:dart_frog_gen/dart_frog_gen.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart' as path;

class _RouteConflict extends Equatable {
  const _RouteConflict(
    this.originalFilePath,
    this.conflictingFilePath,
    this.conflictingEndpoint,
  );

  final String originalFilePath;
  final String conflictingFilePath;
  final String conflictingEndpoint;

  @override
  List<Object> get props => [
        originalFilePath,
        conflictingFilePath,
        conflictingEndpoint,
      ];
}

/// Type definition for callbacks that report route conflicts.
typedef OnRouteConflict = void Function(
  String originalFilePath,
  String conflictingFilePath,
  String conflictingEndpoint,
);

/// Reports existence of route conflicts on a [RouteConfiguration].
void reportRouteConflicts(
  RouteConfiguration configuration, {
  /// Callback called when any route conflict is found.
  void Function()? onViolationStart,

  /// Callback called for each route conflict found.
  OnRouteConflict? onRouteConflict,

  /// Callback called when any route conflict is found.
  void Function()? onViolationEnd,
}) {
  final directConflicts = configuration.endpoints.entries
      .where((entry) => entry.value.length > 1)
      .map((e) => _RouteConflict(e.value.first.path, e.value.last.path, e.key));

  final indirectConflicts = <_RouteConflict>{};
  final endpointList = configuration.endpoints.entries.toList();

  for (var i = 0; i < endpointList.length; i++) {
    for (var j = i + 1; j < endpointList.length; j++) {
      final entryA = endpointList[i];
      final entryB = endpointList[j];

      final keyA = entryA.key;
      final keyB = entryB.key;

      final partsA = keyA.split('/');
      final partsB = keyB.split('/');

      if (partsA.length != partsB.length) {
        continue;
      }

      var isConflict = true;
      for (var k = 0; k < partsA.length; k++) {
        final segmentA = partsA[k];
        final segmentB = partsB[k];

        if (segmentA == segmentB) {
          continue;
        }

        final isSegmentADynamic = segmentA.startsWith('<');
        final isSegmentBDynamic = segmentB.startsWith('<');

        if (isSegmentADynamic && isSegmentBDynamic) {
          continue;
        }

        isConflict = false;
        break;
      }

      if (isConflict) {
        final fileA = entryA.value.first;
        final fileB = entryB.value.first;

        final pathA = fileA.path;
        final pathB = fileB.path;

        final orderedPaths = [pathA, pathB]..sort();
        final orderedKeys = [keyA, keyB]..sort();

        indirectConflicts.add(
          _RouteConflict(
            orderedPaths[0],
            orderedPaths[1],
            orderedKeys[0],
          ),
        );
      }
    }
  }

  final conflictingEndpoints = [...directConflicts, ...indirectConflicts];

  if (conflictingEndpoints.isNotEmpty) {
    onViolationStart?.call();
    for (final conflict in conflictingEndpoints) {
      final originalFilePath = path.normalize(
        path.join('routes', conflict.originalFilePath),
      );
      final conflictingFilePath = path.normalize(
        path.join('routes', conflict.conflictingFilePath),
      );
      onRouteConflict?.call(
        originalFilePath,
        conflictingFilePath,
        conflict.conflictingEndpoint,
      );
    }
    onViolationEnd?.call();
  }
}
