import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/katalog_screen.dart';
import 'screens/moji_zakupi_screen.dart';
import 'screens/zakup_detalj_screen.dart';
import 'screens/predmet_detalj_screen.dart';
import 'screens/zahtev_forma_screen.dart';

/// Korenski navigator: ekrani koji prekrivaju donju traku idu ovde
final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _GlavniOkvir(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
                    GoRoute(
            path: '/',
            builder: (context, state) => const KatalogScreen(),
            routes: [
              // /predmet/p-1, /predmet/p-2 ...
                            GoRoute(
                path: 'predmet/:id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    PredmetDetaljScreen(id: state.pathParameters['id']!),
                routes: [
                  // /predmet/p-1/zahtev
                  GoRoute(
                    path: 'zahtev',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => ZahtevFormaScreen(
                      predmetId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/zakupi',
            builder: (context, state) => const MojiZakupiScreen(),
            routes: [
              // /zakupi/z-1, /zakupi/z-2 ...
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) =>
                    ZakupDetaljScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ]),
      ],
    ),
  ],
);

/// Okvir aplikacije
class _GlavniOkvir extends StatelessWidget {
  const _GlavniOkvir({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.diamond_outlined),
            selectedIcon: Icon(Icons.diamond),
            label: 'Katalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Moji zakupi',
          ),
        ],
      ),
    );
  }
}