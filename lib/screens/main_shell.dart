import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'folder/folder_select_screen.dart';
import 'people/people_screen.dart';
import 'profile/profile_screen.dart';
import 'timeline/timeline_screen.dart';
import '../utils/constants.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _screens = const [
    FolderSelectScreen(),
    TimelineScreen(),
    PeopleScreen(),
    ProfileScreen(),
  ];

  final _items = const [
    (Icons.folder_rounded, 'Folders'),
    (Icons.photo_library_rounded, 'Timeline'),
    (Icons.face_retouching_natural, 'People'),
    (Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          IndexedStack(index: _index, children: _screens),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: const Icon(Icons.menu_rounded, color: AppColors.textDark, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = i == _index;
                final (icon, label) = _items[i];
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.brandGradient : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: selected ? Colors.white : AppColors.textMuted, size: 22),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
