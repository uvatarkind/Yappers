import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yapper/core/theme/app_theme.dart';
import 'package:yapper/features/profile/domain/entities/profile_entity.dart';
import 'package:yapper/features/profile/presentation/bloc/theme/theme_event.dart';
import 'package:yapper/features/profile/presentation/bloc/theme/theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(AppTheme.getTheme(Emotion.happy))) {
    on<EmotionChanged>((event, emit) {
      emit(ThemeState(AppTheme.getTheme(event.emotion)));
    });
  }
}
