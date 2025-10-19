import 'package:equatable/equatable.dart';
import 'package:yapper/features/profile/domain/entities/profile_entity.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class EmotionChanged extends ThemeEvent {
  final Emotion emotion;

  const EmotionChanged(this.emotion);

  @override
  List<Object> get props => [emotion];
}
