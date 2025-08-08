import 'package:dart_frog_gen/dart_frog_gen.dart';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class _MockRouteConfiguration extends Mock implements RouteConfiguration {}

void main() {
  group('reportRouteConflicts', () {
    late RouteConfiguration configuration;

    late bool violationStartCalled;
    late bool violationEndCalled;
    late List<String> conflicts;

    setUp(() {
      configuration = _MockRouteConfiguration();

      violationStartCalled = false;
      violationEndCalled = false;
      conflicts = [];
    });

    test('reports nothing when there are no endpoints', () {
      when(() => configuration.endpoints).thenReturn({});

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isFalse);
      expect(violationEndCalled, isFalse);
      expect(conflicts, isEmpty);
    });

    test('reports nothing when there are endpoints and no conflicts', () {
      when(() => configuration.endpoints).thenReturn({
        '/': const [
          RouteFile(
            name: 'index',
            path: 'index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/hello': const [
          RouteFile(
            name: 'hello',
            path: 'hello.dart',
            route: '/hello',
            params: [],
            wildcard: false,
          ),
        ],
      });

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isFalse);
      expect(violationEndCalled, isFalse);
      expect(conflicts, isEmpty);
    });

    test('reports single conflict when there is one endpoint with conflicts',
        () {
      when(() => configuration.endpoints).thenReturn({
        '/': const [
          RouteFile(
            name: 'index',
            path: 'index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/hello': const [
          RouteFile(
            name: 'hello',
            path: 'hello.dart',
            route: '/hello',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: 'hello_index',
            path: 'hello/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
      });

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isTrue);
      expect(violationEndCalled, isTrue);
      expect(conflicts, ['/hello']);
    });

    test(
        'reports multiple conflicts '
        'when there are multiple endpoint with conflicts', () {
      when(() => configuration.endpoints).thenReturn({
        '/': const [
          RouteFile(
            name: 'index',
            path: 'index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/hello': const [
          RouteFile(
            name: 'hello',
            path: 'hello.dart',
            route: '/hello',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: 'hello_index',
            path: 'hello/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
        '/echo': const [
          RouteFile(
            name: 'echo',
            path: 'echo.dart',
            route: '/echo',
            params: [],
            wildcard: false,
          ),
          RouteFile(
            name: 'echo_index',
            path: 'echo/index.dart',
            route: '/',
            params: [],
            wildcard: false,
          ),
        ],
      });

      reportRouteConflicts(
        configuration,
        onViolationStart: () {
          violationStartCalled = true;
        },
        onRouteConflict: (_, __, conflictingEndpoint) {
          conflicts.add(conflictingEndpoint);
        },
        onViolationEnd: () {
          violationEndCalled = true;
        },
      );

      expect(violationStartCalled, isTrue);
      expect(violationEndCalled, isTrue);
      expect(conflicts, ['/hello', '/echo']);
    });

    test(
      'reports no conflict when dynamic directories conflict with non dynamic files',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/cars/<id>': const [
            RouteFile(
              name: r'cars_$id_index',
              path: '../routes/cars/[id]/index.dart',
              route: '/',
              params: [],
              wildcard: false,
            ),
          ],
          '/cars/mine': const [
            RouteFile(
              name: 'cars_mine',
              path: '../routes/cars/mine.dart',
              route: '/mine',
              params: [],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () {
            violationStartCalled = true;
          },
          onRouteConflict: (
            originalFilePath,
            conflictingFilePath,
            conflictingEndpoint,
          ) {
            conflicts.add('$originalFilePath and '
                '$conflictingFilePath -> '
                '$conflictingEndpoint');
          },
          onViolationEnd: () {
            violationEndCalled = true;
          },
        );

        expect(violationStartCalled, isFalse);
        expect(violationEndCalled, isFalse);
        expect(conflicts, isEmpty);
      },
    );

    test(
      'reports conflict when there are conflicting dynamic routes',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/turtles/<id>': const [
            RouteFile(
              name: r'turtles_$id_index',
              path: '../routes/turtles/[id]/index.dart',
              route: '/turtles/<id>',
              params: [],
              wildcard: false,
            ),
          ],
          '/turtles/<name>': const [
            RouteFile(
              name: r'turtles_$name_index',
              path: '../routes/turtles/[name]/index.dart',
              route: '/turtles/<name>',
              params: [],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () {
            violationStartCalled = true;
          },
          onRouteConflict: (
            originalFilePath,
            conflictingFilePath,
            conflictingEndpoint,
          ) {
            conflicts.add(
              '$originalFilePath and '
              '$conflictingFilePath -> '
              '$conflictingEndpoint',
            );
          },
          onViolationEnd: () {
            violationEndCalled = true;
          },
        );

        expect(violationStartCalled, isTrue);
        expect(violationEndCalled, isTrue);
        expect(
          conflicts,
          [
            '${path.normalize('routes/../routes/turtles/[id]/index.dart')} and ${path.normalize('routes/../routes/turtles/[name]/index.dart')} -> /turtles/<id>',
          ],
        );
      },
    );

    test(
      'reports no conflict when there is a dynamic and a static route',
      () {
        when(() => configuration.endpoints).thenReturn({
          '/': const [
            RouteFile(
              name: 'index',
              path: '../routes/index.dart',
              route: '/',
              params: [],
              wildcard: false,
            ),
          ],
          '/<foo>': const [
            RouteFile(
              name: 'foo',
              path: '../routes/[foo].dart',
              route: '/<foo>',
              params: ['foo'],
              wildcard: false,
            ),
          ],
          '/bar': const [
            RouteFile(
              name: 'bar',
              path: '../routes/bar.dart',
              route: '/bar',
              params: [],
              wildcard: false,
            ),
          ],
        });

        reportRouteConflicts(
          configuration,
          onViolationStart: () {
            violationStartCalled = true;
          },
          onRouteConflict: (
            originalFilePath,
            conflictingFilePath,
            conflictingEndpoint,
          ) {
            conflicts.add(
              '$originalFilePath and '
              '$conflictingFilePath -> '
              '$conflictingEndpoint',
            );
          },
          onViolationEnd: () {
            violationEndCalled = true;
          },
        );

        expect(violationStartCalled, isFalse);
        expect(violationEndCalled, isFalse);
        expect(conflicts, isEmpty);
      },
    );
  });
}
