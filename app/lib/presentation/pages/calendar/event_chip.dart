import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n.dart';
import '../../../core/palette.dart';
import '../../../core/recurrence.dart';
import '../../providers/auth_controller.dart';
import '../../providers/core_providers.dart';
import '../../widgets/common.dart';

/// Miniatura wydarzenia w kafelku dnia.
/// Tło w kolorze wydarzenia (półprzezroczyste), tekst o automatycznie dobranym kontraście,
/// mini avatar autora przy wydarzeniach grupowych innych osób.
class EventChip extends ConsumerWidget {
  const EventChip({
    super.key,
    required this.occurrence,
    this.showTime = false,
    this.dimmed = false,
    this.elevated = false,
    this.height = 17,
  });

  final Occurrence occurrence;
  final bool showTime;
  final bool dimmed;
  final bool elevated;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = occurrence.event;
    final me = ref.watch(currentUserProvider);
    final author = ref.watch(membersIndexProvider)[event.createdById];
    final showAvatar = event.groupId != null && event.createdById != me?.id;
    final (bg, fg) = Palette.chip(Palette.parse(occurrence.color), Theme.of(context).brightness);
    final time = !occurrence.allDay && showTime ? '${Fmt.time(occurrence.start)} ' : '';

    return Semantics(
      label: '${occurrence.allDay ? '' : Fmt.time(occurrence.start)} ${occurrence.title}'
          '${showAvatar && author != null ? ', ${author.displayName}' : ''}',
      button: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: dimmed ? 0.35 : 1,
        child: Container(
          height: height,
          padding: EdgeInsets.only(left: showAvatar ? 1.5 : 5, right: 4),
          decoration: BoxDecoration(
            color: elevated ? Color.alphaBlend(bg, Theme.of(context).colorScheme.surface) : bg,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: elevated ? [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            children: [
              if (showAvatar) ...[
                Avatar(id: event.createdById, name: author?.displayName ?? '?', url: author?.avatarUrl, size: height - 3),
                const SizedBox(width: 3),
              ],
              Expanded(
                child: Text(
                  '$time${occurrence.title}',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(color: fg, fontSize: height * 0.6, fontWeight: FontWeight.w700, height: 1.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
