import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yapper/features/profile/presentation/bloc/theme/theme_event.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

class EmotionSelector extends StatelessWidget {
  const EmotionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedEmotion =
        context.select((ProfileBloc bloc) => bloc.state.userProfile?.emotion);

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: Emotion.values.map((emotion) {
        final isSelected = selectedEmotion == emotion;
        return ChoiceChip(
          label: Text(
            '${_getEmotionEmoji(emotion)} ${emotion.name[0].toUpperCase()}${emotion.name.substring(1)}',
          ),
          selected: isSelected,
          onSelected: (bool selected) {
            if (selected) {
              context
                  .read<ProfileBloc>()
                  .add(EmotionChanged(emotion) as ProfileEvent);
            }
          },
          selectedColor: Theme.of(context).primaryColor.withOpacity(0.8),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          backgroundColor: Colors.grey[200],
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }

  String _getEmotionEmoji(Emotion emotion) {
    switch (emotion) {
      case Emotion.happy:
        return '😊';
      case Emotion.sad:
        return '😢';
      case Emotion.angry:
        return '😡';
      case Emotion.disgusted:
        return '🤢';
      case Emotion.fear:
        return '😨';
    }
  }
}
