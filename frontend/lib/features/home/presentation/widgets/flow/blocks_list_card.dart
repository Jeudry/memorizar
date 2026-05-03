import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/presentation/widgets/glass.dart';
import '../../../../../core/theme.dart';
import 'verse_block.dart';

class BlocksListCard extends StatefulWidget {
  final List<String> blocks;
  final List<String> correctOrder;
  final bool checked;
  final void Function(List<String>) onReorder;
  
  const BlocksListCard({
    super.key, 
    required this.blocks,
    required this.correctOrder,
    required this.checked,
    required this.onReorder,
  });

  @override
  State<BlocksListCard> createState() => _BlocksListCardState();
}

class _BlocksListCardState extends State<BlocksListCard> {
  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.all(14),
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: widget.blocks.length,
          onReorderStart: (_) => HapticFeedback.lightImpact(),
          onReorderEnd: (_) => HapticFeedback.lightImpact(),
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.02,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: RefColors.pink.withValues(alpha: 0.3 * animation.value),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: child,
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final newOrder = List<String>.from(widget.blocks);
            final item = newOrder.removeAt(oldIndex);
            newOrder.insert(newIndex, item);
            widget.onReorder(newOrder);
          },
          itemBuilder: (context, index) {
            final block = widget.blocks[index];
            final isCorrect = widget.checked && widget.correctOrder[index] == block;
            final isWrong = widget.checked && widget.correctOrder[index] != block;

            return ReorderableDragStartListener(
              key: ValueKey(block),
              index: index,
              child: Padding(
                padding: EdgeInsets.only(bottom: index == widget.blocks.length - 1 ? 0 : 8.0),
                child: VerseBlock(
                  '${index + 1}',
                  block,
                  correct: isCorrect,
                  wrong: isWrong,
                  moving: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
