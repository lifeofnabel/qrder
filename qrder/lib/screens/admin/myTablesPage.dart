import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/* GLOBAL COLORS */

const Color kTablesBg = Color(0xFFF8F6F1);
const Color kTablesCard = Color(0xFFFFFEFB);
const Color kTablesInk = Color(0xFF1A1A1A);
const Color kTablesMuted = Color(0xFF777777);
const Color kTablesSoft = Color(0xFFEEEBE4);
const Color kTablesLine = Color(0xFFE7E2D9);
const Color kTablesGold = Color(0xFFD8A75D);
const Color kTablesRed = Color(0xFFD83A34);
const Color kTablesGreen = Color(0xFF2E9E5B);

class MyTablesPage extends StatefulWidget {
  const MyTablesPage({super.key});

  @override
  State<MyTablesPage> createState() => _MyTablesPageState();
}

class _MyTablesPageState extends State<MyTablesPage> {
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get _tablesRef {
    final uid = _user?.uid;
    if (uid == null) return null;

    return FirebaseFirestore.instance
        .collection('merchants')
        .doc(uid)
        .collection('tables');
  }

  Future<void> _openTableSheet({TableData? table}) async {
    final labelController = TextEditingController(text: table?.label ?? '');
    final roomController = TextEditingController(text: table?.room ?? '');

    final isEdit = table != null;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> saveTable() async {
              if (isSaving) return;

              final ref = _tablesRef;

              if (ref == null) {
                _showSnack('Kein Händler eingeloggt.');
                return;
              }

              final label = labelController.text.trim();
              final room = roomController.text.trim();

              if (label.isEmpty) {
                _showSnack('Bitte Tisch-Bezeichnung eingeben.');
                return;
              }

              setModalState(() {
                isSaving = true;
              });

              try {
                final data = {
                  'label': label,
                  'room': room,
                  'isActive': true,
                  'sortOrder': table?.sortOrder ?? DateTime.now().millisecondsSinceEpoch,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (isEdit) {
                  await ref.doc(table.id).set(data, SetOptions(merge: true));
                } else {
                  await ref.add({
                    ...data,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }

                if (!mounted) return;

                Navigator.of(modalContext).pop();

                _showSnack(
                  isEdit ? 'Tisch gespeichert.' : 'Tisch hinzugefügt.',
                );
              } catch (_) {
                if (mounted) {
                  setModalState(() {
                    isSaving = false;
                  });
                }

                _showSnack('Speichern fehlgeschlagen.');
              }
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(modalContext).size.height * 0.88,
                    ),
                    decoration: const BoxDecoration(
                      color: kTablesCard,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SheetHandle(),
                            const SizedBox(height: 18),
                            Text(
                              isEdit ? 'Tisch bearbeiten' : 'Tisch hinzufügen',
                              style: const TextStyle(
                                color: kTablesInk,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Bezeichnung ist Pflicht. Raum/Bereich ist optional.',
                              style: TextStyle(
                                color: kTablesMuted,
                                fontSize: 13.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SheetInput(
                              controller: labelController,
                              label: 'Bezeichnung',
                              hintText: 'z. B. Tisch 1, Fensterplatz, Bar 2',
                              icon: Icons.table_restaurant_outlined,
                            ),
                            const SizedBox(height: 14),
                            _SheetInput(
                              controller: roomController,
                              label: 'Raum / Bereich',
                              hintText: 'z. B. Innenbereich, Terrasse',
                              icon: Icons.meeting_room_outlined,
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isSaving ? null : saveTable,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTablesInk,
                                  disabledBackgroundColor: const Color(0xFFBEB8AE),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                  width: 21,
                                  height: 21,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.3,
                                  ),
                                )
                                    : Text(
                                  isEdit ? 'Speichern' : 'Hinzufügen',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    labelController.dispose();
    roomController.dispose();
  }


  Future<void> _deleteTable(TableData table) async {
    final ref = _tablesRef;

    if (ref == null) {
      _showSnack('Kein Händler eingeloggt.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kTablesCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Tisch löschen?',
            style: TextStyle(
              color: kTablesInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '"${table.label}" wird endgültig gelöscht.',
            style: const TextStyle(
              color: kTablesMuted,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Löschen',
                style: TextStyle(
                  color: kTablesRed,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ref.doc(table.id).delete();
      _showSnack('Tisch gelöscht.');
    } catch (_) {
      _showSnack('Löschen fehlgeschlagen.');
    }
  }

  Map<String, List<TableData>> _groupByRoom(List<TableData> tables) {
    final grouped = <String, List<TableData>>{};

    for (final table in tables) {
      final room = table.room.trim().isEmpty ? 'Ohne Bereich' : table.room.trim();
      grouped.putIfAbsent(room, () => []);
      grouped[room]!.add(table);
    }

    return grouped;
  }

  void _showSnack(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ref = _tablesRef;

    return Scaffold(
      backgroundColor: kTablesBg,
      body: SafeArea(
        child: ref == null
            ? const _NotLoggedInState()
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _ErrorState();
            }

            final tables = (snapshot.data?.docs ?? [])
                .map((doc) => TableData.fromDoc(doc))
                .toList()
              ..sort((a, b) {
                final roomCompare = a.room.compareTo(b.room);
                if (roomCompare != 0) return roomCompare;
                return a.label.compareTo(b.label);
              });

            final grouped = _groupByRoom(tables);

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _topBar(context),
                      const SizedBox(height: 22),
                      const Text(
                        'Tische & Plätze',
                        style: TextStyle(
                          color: kTablesInk,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.9,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Diese Plätze können Kunden auswählen, wenn direkte Bestellungen aktiviert sind.',
                        style: TextStyle(
                          color: kTablesMuted,
                          fontSize: 14.5,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _InfoCard(count: tables.length),
                      const SizedBox(height: 18),
                      if (!snapshot.hasData)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(
                              color: kTablesInk,
                            ),
                          ),
                        )
                      else if (tables.isEmpty)
                        const _EmptyState()
                      else
                        ...grouped.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _RoomSection(
                              roomName: entry.key,
                              tables: entry.value,
                              onEdit: (table) =>
                                  _openTableSheet(table: table),
                              onDelete: _deleteTable,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                Positioned(
                  left: 22,
                  right: 22,
                  bottom: 20,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _openTableSheet(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTablesInk,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(
                        'Tisch hinzufügen',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: kTablesSoft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: kTablesInk,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kTablesSoft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'Qrder Plätze',
            style: TextStyle(
              color: kTablesInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

/* DATA */

class TableData {
  final String id;
  final String label;
  final String room;
  final bool isActive;
  final int sortOrder;

  const TableData({
    required this.id,
    required this.label,
    required this.room,
    required this.isActive,
    required this.sortOrder,
  });

  factory TableData.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return TableData(
      id: doc.id,
      label: data['label']?.toString() ??
          data['name']?.toString() ??
          data['title']?.toString() ??
          data['bezeichnung']?.toString() ??
          data['Bezeichnung']?.toString() ??
          doc.id,
      room: data['room']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? true,
      sortOrder: data['sortOrder'] is int
          ? data['sortOrder'] as int
          : 999999,
    );
  }
}

/* UI */

class _InfoCard extends StatelessWidget {
  final int count;

  const _InfoCard({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: kTablesCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kTablesLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kTablesInk,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.table_restaurant_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Plätze hinterlegt',
                  style: const TextStyle(
                    color: kTablesInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kunden wählen später einen Platz aus, bevor sie direkt bestellen.',
                  style: TextStyle(
                    color: kTablesMuted,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomSection extends StatelessWidget {
  final String roomName;
  final List<TableData> tables;
  final ValueChanged<TableData> onEdit;
  final ValueChanged<TableData> onDelete;

  const _RoomSection({
    required this.roomName,
    required this.tables,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kTablesCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kTablesLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.meeting_room_outlined,
                color: kTablesInk,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  roomName,
                  style: const TextStyle(
                    color: kTablesInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kTablesSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${tables.length}',
                  style: const TextStyle(
                    color: kTablesInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          GridView.builder(
            itemCount: tables.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) {
              final table = tables[index];

              return _TableTile(
                table: table,
                onEdit: () => onEdit(table),
                onDelete: () => onDelete(table),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  final TableData table;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TableTile({
    required this.table,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kTablesSoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kTablesLine),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -2,
                top: -2,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: kTablesRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: kTablesRed,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kTablesInk,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.table_bar_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    table.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTablesInk,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'tippen zum Bearbeiten',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kTablesMuted,
                      fontSize: 10.8,
                      fontWeight: FontWeight.w700,
                    ),
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

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;

  const _SheetInput({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTablesInk,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
            color: kTablesInk,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: kTablesMuted,
              size: 20,
            ),
            filled: true,
            fillColor: kTablesSoft,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: kTablesLine),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(color: kTablesLine),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: const BorderSide(
                color: kTablesInk,
                width: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: kTablesLine,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: kTablesCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kTablesLine),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            color: kTablesMuted,
            size: 45,
          ),
          SizedBox(height: 14),
          Text(
            'Noch keine Tische',
            style: TextStyle(
              color: kTablesInk,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Füge Plätze hinzu, damit Kunden direkte Bestellungen einem Tisch zuordnen können.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTablesMuted,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotLoggedInState extends StatelessWidget {
  const _NotLoggedInState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Kein Händler eingeloggt.',
        style: TextStyle(
          color: kTablesMuted,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Tische konnten nicht geladen werden.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTablesMuted,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}