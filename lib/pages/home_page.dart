import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  List<Widget> get pages => const [
    Center(child: Text('home')),
    Center(child: Text('search')),
    Center(child: Text('post')),
    Center(child: Text('notification')),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      bottomBar: GlassTabBar.bottom(
        settings: LiquidGlassSettings(chromaticAberration: 1),
        tabs: [
          GlassTab(icon: FaIcon(FontAwesomeIcons.house)),
          GlassTab(icon: FaIcon(FontAwesomeIcons.magnifyingGlass)),
          GlassTab(icon: FaIcon(FontAwesomeIcons.plus)),
          GlassTab(icon: FaIcon(FontAwesomeIcons.bell)),
          GlassTab(icon: FaIcon(FontAwesomeIcons.person)),
        ],
        selectedIndex: selectedIndex,
        onTabSelected: (i) => setState(() => selectedIndex = i),
      ),
      body: pages[selectedIndex],
    );
  }
}

/// Profile tab: shows who is signed in, prints the user, signs out.
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _auth = AuthService.instance;
  String? _userJson;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(user?.email ?? user?.id ?? 'Signed in',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            _button('Print current user', () {
              // Prints to the debug console and shows it below.
              setState(() => _userJson = _auth.printCurrentUser());
            }),
            const SizedBox(height: 12),
            _button('Sign out', () => _auth.signOut()),
            if (_userJson != null) ...[
              const SizedBox(height: 24),
              Text(
                _userJson!,
                style: const TextStyle(fontSize: 12, fontFamily: 'Menlo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback onTap) {
    return LayoutBuilder(
      builder: (context, c) => GlassButton.custom(
        useOwnLayer: true,
        width: c.maxWidth,
        height: 52,
        shape: const LiquidRoundedRectangle(borderRadius: 26),
        onTap: onTap,
        label: label,
        child: Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}