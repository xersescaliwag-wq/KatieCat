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
        _HomeTab(),
        _SearchTab(),
        _CreatePostTab(),
        _NotificationsTab(),
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

// -----------------------------------------------------------------------------
// Home Feed Tab
// -----------------------------------------------------------------------------

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final List<Map<String, dynamic>> _posts = [
    {
      'name': 'Katie the Cat',
      'username': '@katiecat',
      'time': '2h ago',
      'avatarColor': const Color(0xFFFF4081),
      'initials': 'KC',
      'content':
          'Purr-fect day for a nap in the sun! ☀️ What is everyone up to today?',
      'likes': 24,
      'isLiked': false,
      'comments': 5,
    },
    {
      'name': 'Alex Rivera',
      'username': '@arivera',
      'time': '5h ago',
      'avatarColor': const Color(0xFF7C4DFF),
      'initials': 'AR',
      'content':
          'Just launched the new Liquid Glass UI in Flutter! The refraction and blur effects are incredible. 💎✨',
      'likes': 89,
      'isLiked': true,
      'comments': 12,
    },
    {
      'name': 'Dev Community',
      'username': '@flutter_devs',
      'time': '1d ago',
      'avatarColor': const Color(0xFF00B8D4),
      'initials': 'FD',
      'content':
          'Welcome to katiecat app! Connect, share posts, and explore beautiful glassmorphism designs.',
      'likes': 142,
      'isLiked': false,
      'comments': 28,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // Top Header Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'katiecat',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: const FaIcon(
                          FontAwesomeIcons.heart,
                          color: CupertinoColors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: const FaIcon(
                          FontAwesomeIcons.paperPlane,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stories horizontal bar
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 6,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final isMe = index == 0;
                  final names = ['You', 'Katie', 'Alex', 'Sarah', 'Leo', 'Mia'];
                  final colors = [
                    const Color(0xFF7C4DFF),
                    const Color(0xFFFF4081),
                    const Color(0xFF00B8D4),
                    const Color(0xFFFFB300),
                    const Color(0xFF00E676),
                    const Color(0xFFFF5252),
                  ];
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isMe
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFFF4081),
                                    Color(0xFF7C4DFF),
                                  ],
                                ),
                          color: isMe ? const Color(0x33FFFFFF) : null,
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors[index % colors.length],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isMe ? '+' : names[index][0],
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        names[index],
                        style: const TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // Posts List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _posts[index];
                  final isLiked = post['isLiked'] as bool;
                  final likes = post['likes'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author Row
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: post['avatarColor'] as Color,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  post['initials'] as String,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['name'] as String,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${post['username']} • ${post['time']}',
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {},
                                child: const FaIcon(
                                  FontAwesomeIcons.ellipsis,
                                  color: Color(0x99FFFFFF),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Content
                          Text(
                            post['content'] as String,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Actions Row
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    post['isLiked'] = !isLiked;
                                    post['likes'] =
                                        isLiked ? likes - 1 : likes + 1;
                                  });
                                },
                                child: Row(
                                  children: [
                                    FaIcon(
                                      isLiked
                                          ? FontAwesomeIcons.solidHeart
                                          : FontAwesomeIcons.heart,
                                      color: isLiked
                                          ? const Color(0xFFFF4081)
                                          : const Color(0x99FFFFFF),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${post['likes']}',
                                      style: TextStyle(
                                        color: isLiked
                                            ? const Color(0xFFFF4081)
                                            : const Color(0x99FFFFFF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.comment,
                                    color: Color(0x99FFFFFF),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${post['comments']}',
                                    style: const TextStyle(
                                      color: Color(0x99FFFFFF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              const FaIcon(
                                FontAwesomeIcons.shareNodes,
                                color: Color(0x99FFFFFF),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _posts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Search Tab
// -----------------------------------------------------------------------------

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _searchController = TextEditingController();
  int _selectedCategory = 0;

  final List<String> _categories = [
    'Trending',
    'Cats 🐱',
    'Tech 💻',
    'Photos 📷',
    'People 👥'
  ];

  final List<Map<String, dynamic>> _users = [
    {
      'name': 'Katie Cat Official',
      'handle': '@katiecat',
      'bio': 'Official account for katiecat app 🐱',
      'avatarColor': const Color(0xFFFF4081),
      'initials': 'KC',
      'isFollowing': true,
    },
    {
      'name': 'Alex Rivera',
      'handle': '@arivera',
      'bio': 'Flutter developer & UI designer 🎨',
      'avatarColor': const Color(0xFF7C4DFF),
      'initials': 'AR',
      'isFollowing': false,
    },
    {
      'name': 'Flutter Devs Community',
      'handle': '@flutter_devs',
      'bio': 'Building the future of cross-platform apps 💙',
      'avatarColor': const Color(0xFF00B8D4),
      'initials': 'FD',
      'isFollowing': true,
    },
    {
      'name': 'Sarah Connor',
      'handle': '@sconnor',
      'bio': 'Tech enthusiast and pet lover 🐾',
      'avatarColor': const Color(0xFFFFB300),
      'initials': 'SC',
      'isFollowing': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredUsers = _users.where((user) {
      final name = (user['name'] as String).toLowerCase();
      final handle = (user['handle'] as String).toLowerCase();
      return name.contains(query) || handle.contains(query);
    }).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // Search Title & Field
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassTextField(
                    useOwnLayer: true,
                    controller: _searchController,
                    placeholder: 'Search accounts or topics...',
                    onChanged: (_) => setState(() {}),
                    prefixIcon: const Icon(
                      CupertinoIcons.search,
                      color: Color(0xB3FFFFFF),
                      size: 20,
                    ),
                    shape: const LiquidRoundedRectangle(borderRadius: 16),
                  ),
                ],
              ),
            ),
          ),

          // Categories Horizontal Scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategory == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C4DFF)
                            : const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7C4DFF)
                              : const Color(0x26FFFFFF),
                        ),
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // User list
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = filteredUsers[index];
                  final isFollowing = user['isFollowing'] as bool;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user['avatarColor'] as Color,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              user['initials'] as String,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['name'] as String,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  user['handle'] as String,
                                  style: const TextStyle(
                                    color: Color(0x99FFFFFF),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['bio'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            color: isFollowing
                                ? const Color(0x33FFFFFF)
                                : const Color(0xFF7C4DFF),
                            borderRadius: BorderRadius.circular(16),
                            onPressed: () {
                              setState(() {
                                user['isFollowing'] = !isFollowing;
                              });
                            },
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: filteredUsers.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Create Post Tab
// -----------------------------------------------------------------------------

class _CreatePostTab extends StatefulWidget {
  const _CreatePostTab();

  @override
  State<_CreatePostTab> createState() => _CreatePostTabState();
}

class _CreatePostTabState extends State<_CreatePostTab> {
  final _postController = TextEditingController();
  bool _isPosting = false;
  String? _successMessage;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isPosting = true;
      _successMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() {
      _isPosting = false;
      _postController.clear();
      _successMessage = 'Post published successfully! 🎉';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userEmail = user?.email ?? 'User';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Post',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 20),

            // User Info Box
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7C4DFF),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    userEmail[0].toUpperCase(),
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'Posting to Public Feed',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Textarea
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: CupertinoTextField(
                controller: _postController,
                placeholder: "What's on your mind?",
                placeholderStyle: const TextStyle(color: Color(0x66FFFFFF)),
                style: const TextStyle(color: CupertinoColors.white, fontSize: 16),
                maxLines: 6,
                minLines: 4,
                decoration: const BoxDecoration(),
              ),
            ),
            const SizedBox(height: 16),

            // Attachments Row
            Row(
              children: [
                _actionChip(FontAwesomeIcons.image, 'Photo', const Color(0xFF00B8D4)),
                const SizedBox(width: 10),
                _actionChip(FontAwesomeIcons.video, 'Video', const Color(0xFFFF4081)),
                const SizedBox(width: 10),
                _actionChip(FontAwesomeIcons.hashtag, 'Tag', const Color(0xFFFFB300)),
              ],
            ),
            const SizedBox(height: 24),

            if (_successMessage != null) ...[
              Text(
                _successMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CupertinoColors.systemGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Publish Button
            LayoutBuilder(
              builder: (context, c) => GlassButton.custom(
                useOwnLayer: true,
                width: c.maxWidth,
                height: 52,
                shape: const LiquidRoundedRectangle(borderRadius: 26),
                onTap: _isPosting ? () {} : _publish,
                label: 'Publish Post',
                child: _isPosting
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FaIcon(FontAwesomeIcons.paperPlane,
                              size: 18, color: CupertinoColors.white),
                          SizedBox(width: 10),
                          Text(
                            'Publish Post',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(dynamic icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x26FFFFFF)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon as IconData, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Notifications Tab
// -----------------------------------------------------------------------------

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Likes', 'Mentions'];

  final List<Map<String, dynamic>> _notifications = [
    {
      'name': 'Katie the Cat',
      'action': 'liked your post.',
      'time': '10m ago',
      'icon': FontAwesomeIcons.solidHeart,
      'iconColor': const Color(0xFFFF4081),
      'type': 'Likes',
      'avatarColor': const Color(0xFFFF4081),
      'initials': 'KC',
    },
    {
      'name': 'Alex Rivera',
      'action': 'commented: "Great glass UI!"',
      'time': '1h ago',
      'icon': FontAwesomeIcons.comment,
      'iconColor': const Color(0xFF00B8D4),
      'type': 'Mentions',
      'avatarColor': const Color(0xFF7C4DFF),
      'initials': 'AR',
    },
    {
      'name': 'Flutter Devs',
      'action': 'started following you.',
      'time': '3h ago',
      'icon': FontAwesomeIcons.userPlus,
      'iconColor': const Color(0xFF7C4DFF),
      'type': 'All',
      'avatarColor': const Color(0xFF00B8D4),
      'initials': 'FD',
    },
    {
      'name': 'Sarah Connor',
      'action': 'liked your comment.',
      'time': '1d ago',
      'icon': FontAwesomeIcons.solidHeart,
      'iconColor': const Color(0xFFFF4081),
      'type': 'Likes',
      'avatarColor': const Color(0xFFFFB300),
      'initials': 'SC',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filter = _filters[_selectedFilter];
    final items = filter == 'All'
        ? _notifications
        : _notifications.where((n) => n['type'] == filter).toList();

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.white,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7C4DFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilter == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF7C4DFF)
                            : const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF7C4DFF)
                              : const Color(0x26FFFFFF),
                        ),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Notifications List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x26FFFFFF)),
                      ),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item['avatarColor'] as Color,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  item['initials'] as String,
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF0B1026),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    size: 10,
                                    color: item['iconColor'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${item['name']} ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: item['action'] as String,
                                        style: const TextStyle(
                                            color: Color(0xCCFFFFFF)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['time'] as String,
                                  style: const TextStyle(
                                    color: Color(0x99FFFFFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}