// lib/sos_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF3075FF);
    const pageBg = Color(0xFFF4F5F7);

    // Example data (2 items)
    final incidents = <SosIncident>[
      SosIncident(
        identity: Identity(name: 'Alex', studentId: 'A1234567'),
        journey: Journey(
          startPoint: 'Library',
          destination: 'Dorm',
          startedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        companionship: Companionship.alone,
        createdAt: DateTime.now(),
      ),
      SosIncident(
        identity: Identity(name: 'Joe', studentId: 'A7654321'),
        journey: Journey(
          startPoint: 'Marconi Park',
          destination: 'Hall B',
          startedAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
        companionship: Companionship.ai,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'SOS',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: incidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => SosCard(
          incident: incidents[i],
          onUrgent: () {
            // TODO: handle urgent action (e.g., navigate or accept assignment)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Responding to ${incidents[i].identity.name}...')),
            );
          },
        ),
      ),
      bottomNavigationBar: const _BottomBar(current: 0),
    );
  }
}

/* ======================= Data models ======================= */

class SosIncident {
  final Identity identity;
  final Journey journey;
  final Companionship companionship;
  final DateTime createdAt;

  SosIncident({
    required this.identity,
    required this.journey,
    required this.companionship,
    required this.createdAt,
  });
}

class Identity {
  final String name;
  final String studentId;
  final String? photoUrl; // optional
  Identity({required this.name, required this.studentId, this.photoUrl});
}

class Journey {
  final String startPoint;
  final String destination;
  final DateTime startedAt;
  Journey({required this.startPoint, required this.destination, required this.startedAt});
}

enum Companionship { alone, ai, friends }

/* ======================= Card ======================= */

class SosCard extends StatelessWidget {
  const SosCard({super.key, required this.incident, this.onUrgent});

  final SosIncident incident;
  final VoidCallback? onUrgent;

  String _elapsedText(DateTime from) {
    final d = DateTime.now().difference(from);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours} hr';
    return '${d.inDays} d';
  }

  String _dateTimePretty(DateTime dt) {
    final weekday = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][dt.weekday - 1];
    final month = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'pm' : 'am';
    return '$weekday, ${dt.day} $month, $h:$m$ap';
  }

  String _companionshipLabel(Companionship c) =>
      c == Companionship.alone ? 'Alone' : c == Companionship.ai ? 'With AI' : 'With friends';

  IconData _companionshipIcon(Companionship c) =>
      c == Companionship.alone ? Icons.person_outline : c == Companionship.ai ? Icons.smart_toy_outlined : Icons.groups_rounded;

  @override
  Widget build(BuildContext context) {
    const chipBg = Color(0xFFE8F0FF);
    const chipText = Color(0xFF3075FF);
    const urgentRed = Color(0xFFD32F2F);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card body sized-to-content (no fixed height)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20), // bottom padding; button overlaps
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar, name, started chip, kebab
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(identity: incident.identity),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                incident.identity.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Chip(label: 'journey started ${_elapsedText(incident.journey.startedAt)}', color: chipBg, textColor: chipText),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_dateTimePretty(incident.createdAt), style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded, color: Colors.black45)),
                ],
              ),
              const SizedBox(height: 10),

              // Student ID
              _KeyValueRow(icon: Icons.badge_outlined, label: 'Student ID', value: incident.identity.studentId),

              // Journey details
              const SizedBox(height: 8),
              Text('Journey details', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              _KeyValueRow(icon: Icons.location_pin, label: 'Start', value: incident.journey.startPoint),
              const SizedBox(height: 4),
              _KeyValueRow(icon: Icons.flag_rounded, label: 'Destination', value: incident.journey.destination),
              const SizedBox(height: 4),
              _KeyValueRow(icon: Icons.timer_outlined, label: 'Elapsed', value: _elapsedText(incident.journey.startedAt)),

              // Companionship
              const SizedBox(height: 12),
              Text('Companionship', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(_companionshipIcon(incident.companionship), size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(_companionshipLabel(incident.companionship), style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),

              const SizedBox(height: 36), // make room above the button
            ],
          ),
        ),

        // Urgent button — bottom-right, red
        Positioned(
          right: 12,
          bottom: -16, // slightly outside for the pill look
          child: ElevatedButton.icon(
            onPressed: onUrgent,
            icon: const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.white),
            label: Text('Respond', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: urgentRed,
              elevation: 6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ),
      ],
    );
  }
}

/* ======================= Small UI helpers ======================= */

class _Avatar extends StatelessWidget {
  const _Avatar({required this.identity});
  final Identity identity;

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF3F4F6);
    final initials = _initials(identity.name);
    final hasPhoto = identity.photoUrl != null && identity.photoUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: 18,
      backgroundColor: bg,
      backgroundImage: hasPhoto
          ? (identity.photoUrl!.startsWith('http')
              ? NetworkImage(identity.photoUrl!)
              : AssetImage(identity.photoUrl!) as ImageProvider)
          : null,
      child: hasPhoto
          ? null
          : Text(initials, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.black87)),
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '•';
    if (parts.length == 1) return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '•';
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: GoogleFonts.poppins(fontSize: 11, color: textColor, fontWeight: FontWeight.w700)),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text('$label:', style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF3075FF);
    const inactive = Color(0xFF9BA0A6);

    Widget item(IconData icon, String label, bool isActive) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? active : inactive, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? active : inactive, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          item(Icons.home, 'Home', current == 0),
          item(Icons.settings, 'Settings', current == 1),
          item(Icons.person, 'Profile', current == 2),
        ],
      ),
    );
  }
}
