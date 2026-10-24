import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets.dart';

/// Настройки: профиль с привязкой к компании и внешний вид
/// (тема, размер текста, обои чата).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showPassport = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;
    final company = state.myCompany;
    final pal = paletteOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(user: me, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            me.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${me.role.label} · @${me.nickname}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Row(label: 'Телефон', value: me.phone),
                if (company != null) ...[
                  _Row(label: 'Компания', value: company.name),
                  _Row(label: 'БИН компании', value: company.bin),
                  _Row(label: 'Должность', value: me.position),
                ] else
                  const _Row(label: 'Компания', value: 'Не состоите в компании'),
                if (me.passport != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Row(
                            label: 'Паспорт',
                            value: _showPassport
                                ? me.passport!
                                : maskPassport(me.passport!),
                          ),
                        ),
                        IconButton(
                          tooltip: _showPassport ? 'Скрыть' : 'Показать',
                          onPressed: () =>
                              setState(() => _showPassport = !_showPassport),
                          icon: Icon(
                            _showPassport
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionLabel('Тема'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Светлая'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Тёмная'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Авто'),
                icon: Icon(Icons.phone_android),
              ),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => state.setThemeMode(s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 6),
          const Text(
            '«Авто» повторяет тему телефона.',
            style: TextStyle(fontSize: 12.5, color: muted),
          ),
          const SizedBox(height: 22),
          const SectionLabel('Размер текста'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in TextSize.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: state.textSize == s,
                  onSelected: (_) => state.setTextSize(s),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionLabel('Обои чата'),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wallpapers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _WallpaperTile(
                index: i,
                selected: state.wallpaperIndex == i,
                onTap: () => state.setWallpaper(i),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: WallpaperBox(
              index: state.wallpaperIndex,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PreviewBubble(
                        text: 'Айгерим, как дела с задачей?',
                        color: pal.bubbleOther,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _PreviewBubble(
                        text: 'Всё сделала, отчёт отправила',
                        color: pal.bubbleMine,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'В демо настройки сбрасываются при перезагрузке страницы. '
            'В рабочей версии они сохраняются в аккаунте.',
            style: TextStyle(fontSize: 12.5, color: muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              context.read<AppState>().signOut();
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: badColor,
            ),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Выйти из аккаунта'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBubble extends StatelessWidget {
  const _PreviewBubble({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  const _WallpaperTile({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = wallpapers[index];
    return Semantics(
      button: true,
      selected: selected,
      label: 'Обои: ${w.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? brand : paletteOf(context).line,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: WallpaperBox(
                  index: index,
                  child: selected
                      ? const Center(
                          child: Icon(Icons.check_circle, color: brand),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(w.name, style: const TextStyle(fontSize: 12, color: muted)),
          ],
        ),
      ),
    );
  }
}
