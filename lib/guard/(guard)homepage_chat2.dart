// lib/homepage_chat2.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '(guard)report.dart';
import 'sos_page.dart';

class GuardRuffAppScreen extends StatefulWidget {
  const GuardRuffAppScreen({super.key});
  @override
  State<GuardRuffAppScreen> createState() => _GuardRuffAppScreenState();
}

class _GuardRuffAppScreenState extends State<GuardRuffAppScreen> {
  final ValueNotifier<int> _selectedChatTab = ValueNotifier<int>(0);

  // Utility method for bottom navigation
  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    const active = Color(0xFF3075FF);
    const inactive = Color(0xFF9BA0A6);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? active : inactive, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isActive ? active : inactive, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF4F5F7);
    const blue = Color(0xFF3075FF);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            // Scale relative to a 375pt-wide iPhone frame
            final w = box.maxWidth.clamp(320.0, 600.0);
            final s = (w / 375.0).clamp(0.85, 1.15);

            // Sizes tuned to your second screenshot
            final headerH     = 160.0 * s;
            final mascotSize   = 96.0  * s;
            final ruffSize     = 28.0  * s;
            final taglineSize  = 12.0  * s;
            final cardH        = 88.0  * s;
            final cardDrop     = 36.0  * s;   // how much the card overlaps
            
            return Column(
              children: [
                // ===== Main content =====
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        // ===== Blue header (compact) =====
                        Container(
                          height: headerH + cardDrop, // include space for overlap
                          decoration: const BoxDecoration(
                            color: blue,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Header row
                              Positioned.fill(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0 * s,
                                    vertical: 12.0 * s,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Mascot (left)
                                      SizedBox(
                                        width: mascotSize,
                                        height: mascotSize,
                                        child: Image.asset(
                                          'assets/guarddog.png', // ensure exists in pubspec
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      SizedBox(width: 12 * s),
                                      // Text (right-aligned)
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'RUFF',
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.bangers(
                                                fontSize: ruffSize,
                                                color: Colors.white,
                                                height: 1.0,
                                              ),
                                            ),
                                            SizedBox(height: 4 * s),
                                            Text(
                                              'will take you home',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontFamily: 'TiltWarp',
                                                color: Colors.white,
                                              ).copyWith(fontSize: taglineSize, height: 1.1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // ===== Floating action card (tight + small) =====
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: -cardDrop,
                                child: Container(
                                  height: cardH,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1F000000),
                                        blurRadius: 16,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildActionCardAsset(
                                        assetPath: 'assets/SOS.png',
                                        label: 'SOS',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const SosPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildActionCardAsset(
                                        assetPath: 'assets/report.png',
                                        label: 'Reports',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const ReportsPage(), // This opens (guard)report.dart
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: cardDrop + 8), // space below the overlap

                        // ===== Chat / History selector (same spot as user) =====
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _selectedChatTab,
                            builder: (context, selectedTab, _) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _TopTabButton(
                                    label: 'Chat',
                                    selected: selectedTab == 0,
                                    onTap: () => _selectedChatTab.value = 0,
                                  ),
                                  const SizedBox(width: 40),
                                  _TopTabButton(
                                    label: 'History',
                                    selected: selectedTab == 1,
                                    onTap: () => _selectedChatTab.value = 1,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // ===== Tab content =====
                        Expanded(
                          child: ValueListenableBuilder<int>(
                            valueListenable: _selectedChatTab,
                            builder: (context, selectedTab, _) {
                              return selectedTab == 0
                                  ? const _ChatListTab()
                                  : const _HistoryTab(); // MODIFIED
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // ===== Bottom nav (labels under icons) =====
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(Icons.home, 'Home', true),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Settings page coming soon!'))),
              child: _buildBottomNavItem(Icons.settings, 'Settings', false),
            ),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Profile page coming soon!'))),
              child: _buildBottomNavItem(Icons.person, 'Profile', false),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// ===== WIDGETS AND DATA MODELS =====
// =================================================================

class _TopTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TopTabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.blue : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 35,
            height: 2,
            color: selected ? Colors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.label,
    required this.color,
    required this.icon,
    required this.radius,
    required this.iconSize,
    required this.gap,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final double radius;
  final double iconSize;
  final double gap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // This widget is not used in the final GuardRuffAppScreen layout,
    // but kept for completeness if it were used elsewhere.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius + 18),
      child: SizedBox(
        width: radius * 5.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
            SizedBox(height: gap),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatItem {
  final String name, last, time, avatarAsset;
  final bool online;
  _ChatItem(this.name, this.last, this.time, this.avatarAsset, {this.online = false});
}

// 1. MODIFIED: Chat list for the guard to communicate with various roles
class _ChatListTab extends StatelessWidget {
  const _ChatListTab();

  @override
  Widget build(BuildContext context) {
    // Represents chats with various users/roles (students, other guards, staff, etc.)
    final items = <_ChatItem>[
      _ChatItem('User: Alice L.', 'Responded to distress signal.', '9:01 pm', 'assets/hellodog.png', online: true),
      _ChatItem('Guard: Beta Team', 'Patrol near East Gate.', '8:27 pm', 'assets/aibuddy.png', online: true),
      _ChatItem('Campus Staff: Admin', 'Access confirmed for zone 3.', '8/29', 'assets/caring.png'),
      _ChatItem('Student: Sam T.', 'Stuck near library exit.', '8/26', 'assets/hellodog.png'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _ChatTile(item: items[i]),
    );
  }
}

class _HistoryItem {
  final String name, status; // name = Event Type, status = User/Context
  final DateTime dateTime;
  _HistoryItem(this.name, this.status, this.dateTime);
}

// 2. MODIFIED: History list showing log of accepted SOS requests
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    // History reflects actions like SOS requests being accepted
    final historyItems = [
      _HistoryItem('SOS Request Accepted', 'User: Sarah K. (Dorm 301)', DateTime.now().subtract(const Duration(minutes: 5))),
      _HistoryItem('SOS Request Accepted', 'User: John D. (Admin Block)', DateTime.now().subtract(const Duration(hours: 1))),
      _HistoryItem('Report Filed', 'Guard: Alpha Team 1', DateTime.now().subtract(const Duration(days: 2))),
      _HistoryItem('Report Filed', 'Guard: Charlie Patrol', DateTime.now().subtract(const Duration(days: 3))),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      itemCount: historyItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _HistoryTile(item: historyItems[i]),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.item});
  final _ChatItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(backgroundImage: AssetImage(item.avatarAsset), radius: 28),
          if (item.online)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 12, height: 12,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Color(0xFF27AE60), shape: BoxShape.circle),
                ),
              ),
            ),
        ],
      ),
      title: Text(item.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: Text(item.last, style: GoogleFonts.poppins(color: Colors.grey.shade600)),
      trailing: Text(item.time, style: GoogleFonts.poppins(fontSize: 12)),
      onTap: () {},
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item});
  final _HistoryItem item;

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return "${dt.month}/${dt.day}, $h:$m";
  }

  // Uses the event name/type to determine color
  Color _getStatusColor(String eventType) {
    switch (eventType) {
      case 'SOS Request Accepted': return const Color(0xFF3075FF); // Blue for accepted SOS
      case 'Report Filed':        return Colors.green;
      default:                    return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventType = item.name;
    final userContext = item.status;
    final eventColor = _getStatusColor(eventType);
    
    return ListTile(
      onTap: () => {}, // Should ideally open event details
      leading: CircleAvatar(
        backgroundColor: eventColor, 
        child: Icon(
            eventType == 'SOS Request Accepted' ? Icons.check_circle_outline : Icons.file_copy_outlined, 
            color: Colors.white,
            size: 20,
        ),
      ),
      title: Text(eventType, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      subtitle: Text(userContext, style: TextStyle(color: Colors.grey.shade600)),
      trailing: Text(_formatDateTime(item.dateTime), style: const TextStyle(fontSize: 12)),
    );
  }
}


Widget _buildActionCardAsset({
  required String assetPath,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}